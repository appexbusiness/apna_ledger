/// A free-form note, with an optional title, stamped with created/updated times.
class QuickNote {
  const QuickNote({
    required this.id,
    required this.text,
    this.title = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickNote copyWith({String? title, String? text, DateTime? updatedAt}) =>
      QuickNote(
        id: id,
        title: title ?? this.title,
        text: text ?? this.text,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory QuickNote.fromMap(Map<String, dynamic> m) => QuickNote(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        text: m['text'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
