library;

/// A mistake found by the AI while checking a student's solution.

class Mistake {
  const Mistake({
    required this.step,
    required this.reason,
    required this.correctApproach,
  });

  /// The incorrect step exactly as the student wrote it.
  final String step;

  /// Why it is wrong.
  final String reason;

  /// What the student should do instead.
  final String correctApproach;

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
    step: (json['step'] as String?) ?? '',
    reason: (json['reason'] as String?) ?? '',
    correctApproach: (json['correctApproach'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {
    'step': step,
    'reason': reason,
    'correctApproach': correctApproach,
  };

  @override
  String toString() => 'Mistake(step: $step, reason: $reason)';
}
