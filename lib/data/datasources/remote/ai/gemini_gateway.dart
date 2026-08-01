library;

import 'dart:convert';
import 'dart:io';

import 'package:ai_photomat/core/constants/app_constants.dart';
import 'package:ai_photomat/core/errors/app_exceptions.dart';
import 'package:ai_photomat/core/utils/image_utils.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';

import 'ai_http_client.dart';

/// Gateway for Google's Gemini `generateContent` REST API.

class GeminiGateway implements AiGateway {
  GeminiGateway({AiHttpClient? http}) : _http = http ?? AiHttpClient();

  final AiHttpClient _http;

  @override
  Future<String> generate({
    required AiSettings settings,
    required String system,
    required String userPrompt,
    List<String> images = const [],
  }) async {
    if (!settings.isConfigured) {
      throw const MissingApiKeyException();
    }

    final model = settings.model.isEmpty
        ? AppConstants.defaultModelByProvider['gemini']!
        : settings.model;
    final url =
        '${AppConstants.geminiBaseUrl}/models/$model:generateContent'
        '?key=${Uri.encodeComponent(settings.apiKey.trim())}';

    final parts = <Map<String, dynamic>>[
      {'text': '$system\n\n$userPrompt'},
    ];
    for (final imagePath in images) {
      final prepared = await ImageUtils.prepareForUpload(imagePath);
      final bytes = await File(prepared?.path ?? imagePath).readAsBytes();
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(bytes)},
      });
    }

    final body = {
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {'maxOutputTokens': 4096, 'temperature': 0.4},
    };

    final response = await _http.postJson(url: url, body: body);
    return _extractText(response);
  }

  @override
  Future<List<String>> listModels(AiSettings settings) async {
    final url =
        '${AppConstants.geminiBaseUrl}/models'
        '?key=${Uri.encodeComponent(settings.apiKey.trim())}'
        '&pageSize=200';
    final json = await _http.getJson(url: url);
    final models = json['models'] as List?;
    if (models == null) return const [];
    return models
        .whereType<Map>()
        .map((m) => m['name'])
        .whereType<String>()
        .map((name) => name.replaceFirst('models/', ''))
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      // Gemini may block output for safety reasons.
      final feedback = (json['promptFeedback'] as Map?)?['blockReason'];
      if (feedback != null) {
        throw AiApiException(
          'The model refused to answer (reason: $feedback). '
          'The problem may be out of scope.',
        );
      }
      throw const AiApiException('The AI provider returned an empty response.');
    }
    final parts = (candidates.first as Map?)?['content']?['parts'] as List?;
    if (parts == null) {
      throw const AiApiException('The AI provider returned an empty response.');
    }
    return parts
        .whereType<Map>()
        .map((e) => e['text'])
        .whereType<String>()
        .join()
        .trim();
  }
}
