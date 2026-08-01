library;

import 'ai_provider.dart';
import 'ai_analysis_result.dart';
import 'mistake.dart';
import 'solution_check_result.dart';
import 'solution_step.dart';

/// A persisted problem record shown in History and re-opened from storage.
///
/// It can hold the output of any mode ([ai], [control], [noai]) — the fields
/// that don't apply to a given mode are simply empty.

class SolvedProblem {
  const SolvedProblem({
    required this.id,
    required this.mode,
    required this.createdAt,
    this.problem = '',
    this.imagePath,
    // AI / No-AI fields
    this.answer = '',
    this.steps = const [],
    this.explanation = '',
    this.simpleExplanation = '',
    // Control fields
    this.correct = false,
    this.score = 0,
    this.mistakes = const [],
    this.hint = '',
    this.feedback = '',
    this.solutionText = '',
    // No-AI fields
    this.calculatorExpression = '',
    this.calculatorResult = '',
    // Unparsed model output (safety net when JSON parsing fails)
    this.rawText = '',
  });

  final String id;
  final SolveMode mode;
  final DateTime createdAt;

  /// The problem statement.
  final String problem;

  /// Path of the original photo (if any).
  final String? imagePath;

  // --- AI / No-AI ---
  final String answer;
  final List<SolutionStep> steps;
  final String explanation;
  final String simpleExplanation;

  // --- Control ---
  final bool correct;
  final int score;
  final List<Mistake> mistakes;
  final String hint;
  final String feedback;
  final String solutionText;

  // --- No-AI calculator ---
  final String calculatorExpression;
  final String calculatorResult;

  /// Unparsed model output kept as a safety net when parsing fails.
  final String rawText;

  factory SolvedProblem.fromAnalysis({
    required AiAnalysisResult analysis,
    required SolveMode mode,
    String? imagePath,
  }) => SolvedProblem(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    mode: mode,
    createdAt: DateTime.now(),
    problem: analysis.problem,
    imagePath: imagePath,
    answer: analysis.answer,
    steps: analysis.steps,
    explanation: analysis.explanation,
    simpleExplanation: analysis.simpleExplanation,
    rawText: analysis.rawText,
  );

  factory SolvedProblem.fromCheck({
    required SolutionCheckResult check,
    String? imagePath,
  }) => SolvedProblem(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    mode: SolveMode.control,
    createdAt: DateTime.now(),
    problem: check.problem,
    imagePath: imagePath,
    solutionText: check.solutionText,
    correct: check.correct,
    score: check.score,
    mistakes: check.mistakes,
    hint: check.hint,
    feedback: check.feedback,
    rawText: check.rawText,
  );

  factory SolvedProblem.fromCalculator({
    required String expression,
    required String result,
  }) => SolvedProblem(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    mode: SolveMode.noAi,
    createdAt: DateTime.now(),
    problem: expression,
    calculatorExpression: expression,
    calculatorResult: result,
  );
}
