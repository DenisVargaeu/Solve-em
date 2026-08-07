library;

import 'package:ai_photomat/core/constants/prompt_templates.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/entities/chat_message.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';

/// Parameters for a chat turn.
class ChatParams {
  const ChatParams({required this.settings, required this.messages});

  final AiSettings settings;

  /// The full conversation so far, including the latest user message.
  final List<ChatMessage> messages;
}

/// Sends a free-form chat turn to the AI tutor. Returns the assistant reply as
/// plain Markdown (chat style, not JSON).

class ChatUseCase {
  ChatUseCase({required AiGatewayResolver resolveGateway})
    : _resolveGateway = resolveGateway;

  final AiGatewayResolver _resolveGateway;

  Future<String> call(ChatParams params) async {
    return _resolveGateway(params.settings).generate(
      settings: params.settings,
      system: PromptTemplates.withLanguage(
        PromptTemplates.chatSystem,
        params.settings.responseLanguage,
      ),
      userPrompt: PromptTemplates.chatUserPrompt(
        messages: params.messages
            .map((m) => (role: m.role.name, text: m.text))
            .toList(),
      ),
    );
  }
}
