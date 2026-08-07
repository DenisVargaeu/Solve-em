library;

import 'package:ai_photomat/core/constants/prompt_templates.dart';
import 'package:ai_photomat/core/errors/app_exceptions.dart';
import 'package:ai_photomat/core/utils/json_parser.dart';
import 'package:ai_photomat/domain/entities/ai_settings.dart';
import 'package:ai_photomat/domain/entities/mistake.dart';
import 'package:ai_photomat/domain/entities/solution_check_result.dart';
import 'package:ai_photomat/domain/repositories/ai_gateway.dart';
import 'package:ai_photomat/domain/repositories/ocr_gateway.dart';
import 'package:ai_photomat/domain/services/markdown_check_parser.dart';

/// Parameters for a Control-mode check.
class CheckSolutionParams {
  const CheckSolutionParams({
    required this.imagePath,
    required this.settings,
    this.ocrText = '',
    this.problemText = '',
    this.sendImage = false,
  });

  /// Local path of the photographed handwritten solution.
  final String imagePath;

  /// The user-configured AI settings.
  final AiSettings settings;

  /// Optional pre-extracted OCR text.
  final String ocrText;

  /// Optional problem statement (when known, e.g. from a previous photo).
  final String problemText;

  /// When true the photo is attached to the request instead of OCR text
  /// (requires a multimodal model).
  final bool sendImage;
}

/// Runs the **Control Mode** flow: OCR the handwritten solution (or attach it
/// directly when [CheckSolutionParams.sendImage] is set), ask the model to
/// check it, and parse the Markdown response into [SolutionCheckResult].

class CheckSolutionUseCase {
  CheckSolutionUseCase({
    required OcrGateway ocrGateway,
    required AiGatewayResolver resolveGateway,
  }) : _ocrGateway = ocrGateway,
       _resolveGateway = resolveGateway;

  final OcrGateway _ocrGateway;
  final AiGatewayResolver _resolveGateway;

  Future<SolutionCheckResult> call(CheckSolutionParams params) async {
    final solutionText = params.ocrText.trim().isNotEmpty
        ? params.ocrText.trim()
        : (params.sendImage ? '' : await _safeOcr(params.imagePath));

    final usesImage = solutionText.isEmpty && params.sendImage;
    if (solutionText.isEmpty && !usesImage) {
      throw const OcrException();
    }

    final raw = await _resolveGateway(params.settings).generate(
      settings: params.settings,
      system: PromptTemplates.withLanguage(
        PromptTemplates.withCustomInstruction(
          PromptTemplates.systemCheck,
          params.settings.customInstruction,
        ),
        params.settings.responseLanguage,
      ),
      userPrompt: PromptTemplates.checkUserPrompt(
        problemText: params.problemText,
        solutionText: solutionText,
        hasImage: usesImage,
      ),
      images: usesImage ? [params.imagePath] : const [],
    );

    return _parse(raw, solutionText: solutionText);
  }

  Future<String> _safeOcr(String path) async {
    try {
      return (await _ocrGateway.extractText(path)).trim();
    } on OcrException {
      return '';
    }
  }

  SolutionCheckResult _parse(String raw, {required String solutionText}) {
    try {
      final json = JsonParser.decodeObject(raw);
      final mistakesRaw = (json['mistakes'] as List?) ?? const [];
      final mistakes = mistakesRaw
          .whereType<Map<String, dynamic>>()
          .map(Mistake.fromJson)
          .toList();

      final hasUsable =
          mistakes.isNotEmpty ||
          (json['feedback'] as String?)?.trim().isNotEmpty == true ||
          (json['hint'] as String?)?.trim().isNotEmpty == true;
      if (!hasUsable) {
        return MarkdownCheckParser.parse(raw, solutionText: solutionText);
      }

      return SolutionCheckResult(
        problem: (json['problem'] as String?) ?? '',
        solutionText:
            (json['solutionText'] as String?)?.trim().isNotEmpty == true
            ? (json['solutionText'] as String).trim()
            : solutionText,
        correct: (json['correct'] as bool?) ?? false,
        score: ((json['score'] as num?) ?? 0).clamp(0, 100).toInt(),
        mistakes: mistakes,
        hint: (json['hint'] as String?) ?? '',
        feedback: (json['feedback'] as String?) ?? '',
        rawText: raw,
      );
    } on FormatException {
      // The model answered in Markdown (with [score]/[mistake]/[hint]/
      // [feedback] tags) instead of JSON.
      return MarkdownCheckParser.parse(raw, solutionText: solutionText);
    }
  }
}
