library;

import 'package:ai_photomat/core/errors/app_exceptions.dart';
import 'package:ai_photomat/domain/entities/ai_provider.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';

import 'gemini_gateway.dart';
import 'openai_compatible_gateway.dart';

/// Creates the correct [AiGateway] for the provider selected in settings.
///
/// Adding a new provider is just: implement `AiGateway`, then add a case here.

class AiGatewayFactory {
  AiGatewayFactory._();

  /// The gateway used for the "no AI configured" fallback.
  static final AiGateway _fallback = OpenAiCompatibleGateway();

  static AiGateway create(AiSettings settings) {
    switch (settings.provider) {
      case AiProvider.gemini:
        return GeminiGateway();
      case AiProvider.openai:
      case AiProvider.openrouter:
      case AiProvider.nvidia:
        return OpenAiCompatibleGateway();
    }
  }

  /// A gateway for connectivity/configuration tests (uses OpenAI format).
  static AiGateway get fallback => _fallback;
}

/// Validates an API key + model by making a tiny chat request.
///
/// Returns `true` on success, or throws an [AppException] with a message that
/// can be shown to the user.
class AiConnectionTester {
  AiConnectionTester(this._gateway);
  final AiGateway _gateway;

  Future<bool> testConnection(AiSettings settings) async {
    await _gateway.generate(
      settings: settings,
      system: 'You are a connectivity test.',
      userPrompt: 'Reply with the single word: OK',
    );
    return true;
  }
}
