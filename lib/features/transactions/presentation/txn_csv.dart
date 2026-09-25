import '../../categories/domain/category.dart';
import '../../../core/utils/formatters.dart';
import '../domain/transaction.dart';

/// Builds the CSV header + rows for a list of transactions, resolving category
/// and sub-category names from [cats]. Reused by every export button.
({List<String> header, List<List<Object?>> rows}) buildTxnCsv(
  List<TxnEntry> txns,
  Map<String, Category> cats,
) {
  const header = [
    'Date',
    'Day',
    'Time',
    'Type',
    'Category',
    'Sub-category',
    'Amount',
    'Note',
    'Person',
    'Interest %',
    'Due date',
    'Recurring',
  ];

  String typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Spending';
      case TransactionType.loanGiven:
        return 'Money given';
      case TransactionType.loanTaken:
        return 'Money taken';
    }
  }

  final rows = <List<Object?>>[];
  for (final t in txns) {
    final cat = cats[t.categoryId];
    final subName = cat?.subCategories
        .where((s) => s.id == t.subCategoryId)
        .map((s) => s.name)
        .join();
    rows.add([
      Formatters.fullDate(t.date),
      Formatters.weekday(t.date),
      Formatters.time(t.date),
      typeLabel(t.type),
      cat?.name ?? '',
      subName ?? '',
      (t.type.sign * t.amount).toStringAsFixed(2),
      t.note,
      t.counterparty ?? '',
      t.interestPercent?.toStringAsFixed(2) ?? '',
      t.dueDate == null ? '' : Formatters.fullDate(t.dueDate!),
      t.recurrence.isRecurring ? t.recurrence.key : '',
    ]);
  }
  return (header: header, rows: rows);
}
