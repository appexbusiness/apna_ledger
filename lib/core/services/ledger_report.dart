/// Plain data handed to the PDF builder, so the exporter (core) doesn't
/// depend on feature models. Built by `runLedgerDownload`.
class LedgerReport {
  const LedgerReport({
    required this.title,
    required this.entries,
    required this.generatedAt,
    this.from,
    this.to,
    this.preparedFor,
  });

  final String title;
  final List<ReportEntry> entries;
  final DateTime generatedAt;

  /// Requested period (null = open-ended).
  final DateTime? from;
  final DateTime? to;

  /// The account holder's name, shown on the cover band.
  final String? preparedFor;
}

class ReportEntry {
  const ReportEntry({
    required this.date,
    required this.typeKey,
    required this.category,
    required this.amount,
    this.subCategory = '',
    this.note = '',
    this.person = '',
    this.recurring = false,
  });

  final DateTime date;

  /// 'income' | 'expense' | 'loanGiven' | 'loanTaken'
  final String typeKey;
  final String category;
  final String subCategory;

  /// Always positive; the type decides the direction.
  final double amount;
  final String note;
  final String person;
  final bool recurring;

  /// Effect on cash in hand (same rule as the app's net balance).
  double get signed =>
      (typeKey == 'income' || typeKey == 'loanTaken') ? amount : -amount;
}
