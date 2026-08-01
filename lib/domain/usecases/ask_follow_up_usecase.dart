library;

import 'package:ai_photomat/core/constants/prompt_templates.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';

/// Parameters for a follow-up chat question.
class AskFollowUpParams {
  const AskFollowUpParams({
    required this.settings,
    required this.problem,
    required this.solutionContext,
    required this.question,
  });

  final AiSettings settings;

  /// Original problem statement.
  final String problem;

  /// The previous solution/explanation, used as context.
  final String solutionContext;

  /// The user's follow-up question.
  final String question;
}

/// Asks the AI a free-form follow-up question about a previously solved
/// problem. Returns plain text (chat style, not JSON).

class AskFollowUpUseCase {
  AskFollowUpUseCase({required AiGatewayResolver resolveGateway})
    : _resolveGateway = resolveGateway;

  final AiGatewayResolver _resolveGateway;

  Future<String> call(AskFollowUpParams params) async {
    return _resolveGateway(params.settings).generate(
      settings: params.settings,
      system: "You are Solve 'em, a friendly math tutor.",
      userPrompt: PromptTemplates.followUpPrompt(
        problem: params.problem,
        solutionContext: params.solutionContext,
        question: params.question,
      ),
    );
  }
}
