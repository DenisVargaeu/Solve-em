library;

import 'package:solveem/core/constants/prompt_templates.dart';
import 'package:solveem/core/errors/app_exceptions.dart';
import 'package:solveem/core/utils/json_parser.dart';
import 'package:solveem/domain/entities/ai_analysis_result.dart';
import 'package:solveem/domain/entities/ai_settings.dart';
import 'package:solveem/domain/entities/solution_step.dart';
import 'package:solveem/domain/repositories/ai_gateway.dart';
import 'package:solveem/domain/repositories/ocr_gateway.dart';
import 'package:solveem/domain/services/markdown_solution_parser.dart';

/// Parameters for an AI-mode analysis.
class AnalyzeProblemParams {
  const AnalyzeProblemParams({
    required this.imagePath,
    required this.settings,
    this.ocrText = '',
    this.sendImage = false,
  });

  /// Local path of the photographed problem.
  final String imagePath;

  /// The user-configured AI settings (provider, key, model).
  final AiSettings settings;

  /// Optional pre-extracted OCR text (when empty, OCR runs inside the use case
  /// unless [sendImage] is true).
  final String ocrText;

  /// When true the photo is attached to the request instead of OCR text
  /// (requires a multimodal model).
  final bool sendImage;
}

/// Runs the **AI Mode** flow: OCR the photo (or attach it directly when
/// [AnalyzeProblemParams.sendImage] is set), ask the model for a full
/// step-by-step solution in Markdown, and parse the response into
/// [AiAnalysisResult].

class AnalyzeProblemUseCase {
  AnalyzeProblemUseCase({
    required OcrGateway ocrGateway,
    required AiGatewayResolver resolveGateway,
  }) : _ocrGateway = ocrGateway,
       _resolveGateway = resolveGateway;

  final OcrGateway _ocrGateway;
  final AiGatewayResolver _resolveGateway;

  Future<AiAnalysisResult> call(AnalyzeProblemParams params) async {
    final problemText = params.ocrText.trim().isNotEmpty
        ? params.ocrText.trim()
        : (params.sendImage ? '' : await _safeOcr(params.imagePath));

    final usesImage = problemText.isEmpty && params.sendImage;
    if (problemText.isEmpty && !usesImage) {
      throw const OcrException();
    }

    final raw = await _resolveGateway(params.settings).generate(
      settings: params.settings,
      system: PromptTemplates.withLanguage(
        PromptTemplates.withCustomInstruction(
          PromptTemplates.systemSolution,
          params.settings.customInstruction,
        ),
        params.settings.responseLanguage,
      ),
      userPrompt: PromptTemplates.solutionUserPrompt(
        problemText: problemText,
        hasImage: usesImage,
      ),
      images: usesImage ? [params.imagePath] : const [],
    );

    return _parse(raw, problemText: problemText);
  }

  /// OCR is the only input now: the photo is never sent to the AI.
  Future<String> _safeOcr(String path) async {
    try {
      return (await _ocrGateway.extractText(path)).trim();
    } on OcrException {
      return '';
    }
  }

  AiAnalysisResult _parse(String raw, {required String problemText}) {
    try {
      final json = JsonParser.decodeObject(raw);
      final stepsRaw = (json['steps'] as List?) ?? const [];
      final steps = stepsRaw
          .whereType<Map<String, dynamic>>()
          .map(SolutionStep.fromJson)
          .toList();

      final result = AiAnalysisResult(
        problem: (json['problem'] as String?)?.trim() ?? problemText,
        answer: (json['answer'] as String?) ?? '',
        steps: steps,
        explanation: (json['explanation'] as String?) ?? '',
        simpleExplanation: (json['simpleExplanation'] as String?) ?? '',
        rawText: raw,
      );

      // A decoded object with no solution content is not a usable answer.
      if (result.steps.isEmpty &&
          result.answer.isEmpty &&
          result.explanation.isEmpty) {
        return MarkdownSolutionParser.parse(raw, fallbackProblem: problemText);
      }
      return result.isEmpty ? result.copyWith(problem: problemText) : result;
    } on FormatException {
      // The model answered in Markdown (with [stepN] tags) instead of JSON.
      return MarkdownSolutionParser.parse(raw, fallbackProblem: problemText);
    }
  }
}
