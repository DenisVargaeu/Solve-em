library;

/// A user-written math note stored locally.

class MathNote {
  const MathNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  MathNote copyWith({String? title, String? content}) => MathNote(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MathNote.fromMap(Map<dynamic, dynamic> map) {
    String str(String key) => (map[key] as String?) ?? '';
    return MathNote(
      id: str('id'),
      title: str('title'),
      content: str('content'),
      createdAt:
          DateTime.tryParse(str('createdAt')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(str('updatedAt')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
