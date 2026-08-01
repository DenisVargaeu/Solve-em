library;

import 'solution_step.dart';

/// Structured result of the **AI Mode** analysis.

class AiAnalysisResult {
  const AiAnalysisResult({
    this.problem = '',
    this.answer = '',
    this.steps = const [],
    this.explanation = '',
    this.simpleExplanation = '',
    this.rawText = '',
  });

  /// The problem written out in text form (OCR + model polish).
  final String problem;

  /// Final answer.
  final String answer;

  /// Ordered step-by-step solution.
  final List<SolutionStep> steps;

  /// Full explanation of the method.
  final String explanation;

  /// Simplified explanation for beginners.
  final String simpleExplanation;

  /// Unparsed model output, kept as a safety net.
  final String rawText;

  bool get isEmpty => problem.isEmpty && answer.isEmpty && steps.isEmpty;

  AiAnalysisResult copyWith({
    String? problem,
    String? answer,
    List<SolutionStep>? steps,
    String? explanation,
    String? simpleExplanation,
    String? rawText,
  }) => AiAnalysisResult(
    problem: problem ?? this.problem,
    answer: answer ?? this.answer,
    steps: steps ?? this.steps,
    explanation: explanation ?? this.explanation,
    simpleExplanation: simpleExplanation ?? this.simpleExplanation,
    rawText: rawText ?? this.rawText,
  );
}
