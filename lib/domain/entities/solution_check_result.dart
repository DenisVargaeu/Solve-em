library;

import 'mistake.dart';

/// Structured result of the **Control Mode** check.

class SolutionCheckResult {
  const SolutionCheckResult({
    this.problem = '',
    this.solutionText = '',
    this.correct = false,
    this.score = 0,
    this.mistakes = const [],
    this.hint = '',
    this.feedback = '',
    this.rawText = '',
  });

  /// The problem that was being solved.
  final String problem;

  /// The student's solution, transcribed from the photo.
  final String solutionText;

  /// Whether the solution is fully correct.
  final bool correct;

  /// Correctness score, 0-100.
  final int score;

  /// Concrete mistakes that were found (empty when correct).
  final List<Mistake> mistakes;

  /// A guiding hint that does not reveal the answer.
  final String hint;

  /// Constructive feedback.
  final String feedback;

  /// Unparsed model output, kept as a safety net.
  final String rawText;

  bool get isEmpty => solutionText.isEmpty && feedback.isEmpty;

  SolutionCheckResult copyWith({
    String? problem,
    String? solutionText,
    bool? correct,
    int? score,
    List<Mistake>? mistakes,
    String? hint,
    String? feedback,
    String? rawText,
  }) => SolutionCheckResult(
    problem: problem ?? this.problem,
    solutionText: solutionText ?? this.solutionText,
    correct: correct ?? this.correct,
    score: score ?? this.score,
    mistakes: mistakes ?? this.mistakes,
    hint: hint ?? this.hint,
    feedback: feedback ?? this.feedback,
    rawText: rawText ?? this.rawText,
  );
}
