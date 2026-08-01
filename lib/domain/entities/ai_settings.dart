library;

import 'ai_provider.dart';

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
  });

  final AiProvider provider;

  /// The user's own API key (empty when not configured).
  final String apiKey;

  /// Model identifier for the configured provider.
  final String model;

  /// Optional custom base URL (OpenAI-compatible providers only).
  final String baseUrl;

  /// Whether the user has everything needed to make an AI call.
  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiSettings copyWith({
    AiProvider? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
  }) => AiSettings(
    provider: provider ?? this.provider,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    baseUrl: baseUrl ?? this.baseUrl,
  );
}
