library;

/// A reference formula shown in the offline Formula Library.

class Formula {
  const Formula({
    required this.id,
    required this.topic,
    required this.name,
    required this.latex,
    required this.description,
    this.example,
  });

  final String id;

  /// Grouping topic, e.g. "Algebra", "Geometry".
  final String topic;

  /// Human readable name, e.g. "Quadratic formula".
  final String name;

  /// LaTeX source rendered by the math widget.
  final String latex;

  /// Short plain-text explanation.
  final String description;

  /// Optional worked example (plain text).
  final String? example;
}
