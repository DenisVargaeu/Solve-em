library;

import 'package:ai_photomat/core/constants/app_constants.dart';
import 'package:ai_photomat/core/errors/app_exceptions.dart';
import 'package:ai_photomat/core/utils/image_utils.dart';
import 'package:ai_photomat/domain/entities/ai_provider.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';

import 'ai_http_client.dart';

/// Gateway for any OpenAI-compatible `/chat/completions` endpoint.
///
/// Used for both the built-in OpenAI provider and OpenRouter (and any other
/// custom base URL the user enters in Settings).

class OpenAiCompatibleGateway implements AiGateway {
  OpenAiCompatibleGateway({AiHttpClient? http})
    : _http = http ?? AiHttpClient();

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

    final baseUrl = _resolvedBaseUrl(settings);
    final url = '${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions';

    final userContent = <Map<String, dynamic>>[
      {'type': 'text', 'text': userPrompt},
    ];
    for (final imagePath in images) {
      final prepared = await ImageUtils.prepareForUpload(imagePath);
      final dataUrl = await ImageUtils.toDataUrl(prepared?.path ?? imagePath);
      userContent.add({
        'type': 'image_url',
        'image_url': {'url': dataUrl},
      });
    }

    final body = {
      'model': settings.model.isEmpty
          ? AppConstants.defaultModel
          : settings.model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': userContent},
      ],
      'max_tokens': 4096,
    };

    final headers = {
      'Authorization': 'Bearer ${settings.apiKey.trim()}',
      if (settings.provider == AiProvider.openrouter) ...{
        'HTTP-Referer': 'https://photomat.app',
        'X-Title': AppConstants.appName,
      },
    };

    final response = await _http.postJson(
      url: url,
      body: body,
      headers: headers,
      timeout: Duration(seconds: settings.requestTimeout),
    );
    return _extractText(response);
  }

  @override
  Future<List<String>> listModels(AiSettings settings) async {
    final baseUrl = _resolvedBaseUrl(settings);
    final url = '${baseUrl.replaceAll(RegExp(r'/$'), '')}/models';

    final headers = <String, String>{};
    if (settings.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${settings.apiKey.trim()}';
    }

    final json = await _http.getJson(
      url: url,
      headers: headers,
      timeout: Duration(seconds: settings.requestTimeout),
    );
    final data = json['data'] as List?;
    if (data == null) return const [];
    return data
        .whereType<Map>()
        .map((m) => m['id'])
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList();
  }

  String _extractText(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const AiApiException('The AI provider returned an empty response.');
    }
    final content = (choices.first as Map?)?['message']?['content'];
    if (content is String && content.isNotEmpty) return content;
    // Some providers (e.g. reasoning models) return content as an array.
    if (content is List) {
      return content
          .whereType<Map>()
          .map((e) => e['text'])
          .whereType<String>()
          .join();
    }
    throw const AiApiException('The AI provider returned an empty response.');
  }

  /// Uses the user's custom base URL, or a sensible default per provider.
  String _resolvedBaseUrl(AiSettings settings) {
    if (settings.baseUrl.trim().isNotEmpty) return settings.baseUrl.trim();
    return switch (settings.provider) {
      AiProvider.openrouter => AppConstants.openRouterBaseUrl,
      AiProvider.nvidia => AppConstants.nvidiaBaseUrl,
      AiProvider.openai => AppConstants.defaultBaseUrl,
      AiProvider.gemini => AppConstants.defaultBaseUrl,
    };
  }
}
