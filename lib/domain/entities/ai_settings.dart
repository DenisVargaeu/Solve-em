library;

import 'ai_provider.dart';
import 'response_language.dart';

/// User-configured AI settings.
///
/// **Never** serialized anywhere other than Secure/Preferences storage via the
/// [SettingsRepository] — and never in source code.

class AiSettings {
  const AiSettings({
    this.provider = AiProvider.openai,
    this.apiKey = '',
    this.model = '',
    this.baseUrl = '',
    this.responseLanguage = ResponseLanguage.english,
    this.requestTimeout = 60,
    this.customInstruction = '',
  });

  final AiProvider provider;

  /// The user's own API key (empty when not configured).
  final String apiKey;

  /// Model identifier for the configured provider.
  final String model;

  /// Optional custom base URL (OpenAI-compatible providers only).
  final String baseUrl;

  /// Language the AI should answer in.
  final ResponseLanguage responseLanguage;

  /// Request timeout in seconds for a single AI API call.
  final int requestTimeout;

  /// Optional custom instruction prepended to every system prompt.
  final String customInstruction;

  /// Whether the user has everything needed to make an AI call.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiSettings copyWith({
    AiProvider? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
    ResponseLanguage? responseLanguage,
    int? requestTimeout,
    String? customInstruction,
  }) => AiSettings(
    provider: provider ?? this.provider,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    baseUrl: baseUrl ?? this.baseUrl,
    responseLanguage: responseLanguage ?? this.responseLanguage,
    requestTimeout: requestTimeout ?? this.requestTimeout,
    customInstruction: customInstruction ?? this.customInstruction,
  );
}
