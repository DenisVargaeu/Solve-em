library;

import '../entities/ai_settings.dart';

/// Resolves an [AiGateway] for the given settings at call time.
///
/// Injected into use cases so they stay decoupled from the data-layer factory.
typedef AiGatewayResolver = AiGateway Function(AiSettings settings);

/// Abstraction over any AI backend (OpenAI-compatible, Gemini, OpenRouter…).
///
/// Implementations build the provider-specific HTTP request and return the
/// model's raw text output. Prompt construction and response parsing happen
/// one level up, so adding a provider only means adding an implementation.

abstract interface class AiGateway {
  /// Sends a chat-style request and returns the model's text output.
  ///
  /// [system] is the system prompt, [userPrompt] the user message and
  /// [images] optional local file paths (or base64 data-URLs) attached to
  /// the request for vision models.
  Future<String> generate({
    required AiSettings settings,
    required String system,
    required String userPrompt,
    List<String> images = const [],
  });

  /// Returns the model ids the provider advertises as available.
  ///
  /// Used by the Settings model picker. Implementations may need a valid API
  /// key (some providers expose public model catalogs).
  Future<List<String>> listModels(AiSettings settings);
}
