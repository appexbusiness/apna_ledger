/// How often a transaction repeats. `once` is a normal one-time entry.
enum Recurrence { once, daily, weekly, monthly, yearly }

extension RecurrenceX on Recurrence {
  String get key => name;
  bool get isRecurring => this != Recurrence.once;

  static Recurrence fromKey(String? key) => Recurrence.values
      .firstWhere((e) => e.name == key, orElse: () => Recurrence.once);
}
