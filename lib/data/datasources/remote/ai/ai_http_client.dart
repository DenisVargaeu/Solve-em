library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';

/// Small HTTP wrapper used by all AI gateways.
///
/// Centralizes timeouts and turns HTTP failures into user-friendly
/// [AppException]s with actionable messages (bad key, rate limit, missing
/// model, …).

class AiHttpClient {
  AiHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GETs [url] and returns the decoded JSON response body.
  Future<Map<String, dynamic>> getJson({
    required String url,
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.aiRequestTimeout);
      return _handle(response);
    } on AiApiException {
      rethrow;
    } on TimeoutException {
      throw NetworkException(cause: TimeoutException('AI request timed out'));
    } catch (e) {
      throw NetworkException(cause: e);
    }
  }

  /// POSTs [body] as JSON and returns the decoded JSON response body.
  Future<Map<String, dynamic>> postJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', ...headers},
            body: jsonEncode(body),
          )
          .timeout(AppConstants.aiRequestTimeout);
      return _handle(response);
    } on AiApiException {
      rethrow;
    } on TimeoutException {
      throw NetworkException(cause: TimeoutException('AI request timed out'));
    } catch (e) {
      throw NetworkException(cause: e);
    }
  }

  Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? const {};
    }

    final error = _errorMessage(response.statusCode, decoded);
    throw AiApiException(
      error,
      cause: response.body,
      code: '${response.statusCode}',
    );
  }

  String _errorMessage(int status, Map<String, dynamic>? body) {
    String? providerMessage;
    final err = body?['error'];
    if (err is Map) {
      providerMessage = err['message'] as String?;
    } else if (err is String) {
      providerMessage = err;
    }

    final prefix = providerMessage == null
        ? ''
        : providerMessage.replaceFirst(RegExp(r'\.$'), '') + '. ';

    return switch (status) {
      400 =>
        '${prefix}The request was rejected. Double-check the model name '
            'and settings.',
      401 || 403 => '${prefix}Your API key was rejected. Check it in Settings.',
      404 =>
        '${prefix}The endpoint or model was not found. Check the base URL '
            'and model name.',
      429 => '${prefix}Rate limit reached. Wait a moment and try again.',
      500 ||
      502 ||
      503 => '${prefix}The AI service is having problems. Try again shortly.',
      _ => '${prefix}Unexpected error (HTTP $status).',
    };
  }
}
