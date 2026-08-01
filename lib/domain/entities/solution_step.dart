library;

/// A single step in a step-by-step solution.

class SolutionStep {
  const SolutionStep({required this.title, required this.description});

  /// Short label such as "Factor out x".
  final String title;

  /// Longer explanation of the step (may contain LaTeX).
  final String description;

  factory SolutionStep.fromJson(Map<String, dynamic> json) => SolutionStep(
    title: (json['title'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {'title': title, 'description': description};

  @override
  String toString() => '$title: $description';
}
