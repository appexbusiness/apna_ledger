/// A user savings goal, e.g. "Emergency fund → ₹50,000 by 31 Dec".
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.target,
    this.saved = 0,
    this.dueDate,
  });

  final String id;
  final String name;
  final double target;
  final double saved;
  final DateTime? dueDate;

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1);
  double get remaining => (target - saved).clamp(0, double.infinity);
  bool get reached => saved >= target && target > 0;

  SavingsGoal copyWith({String? name, double? target, double? saved, DateTime? dueDate}) =>
      SavingsGoal(
        id: id,
        name: name ?? this.name,
        target: target ?? this.target,
        saved: saved ?? this.saved,
        dueDate: dueDate ?? this.dueDate,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory SavingsGoal.fromMap(Map<String, dynamic> m) => SavingsGoal(
        id: m['id'] as String,
        name: m['name'] as String,
        target: (m['target'] as num).toDouble(),
        saved: (m['saved'] as num?)?.toDouble() ?? 0,
        dueDate: m['dueDate'] == null
            ? null
            : DateTime.parse(m['dueDate'] as String),
      );
}
