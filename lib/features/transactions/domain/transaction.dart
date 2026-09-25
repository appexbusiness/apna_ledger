import 'package:equatable/equatable.dart';

import 'recurrence.dart';
import 'transaction_type.dart';

// Re-export so any file importing `transaction.dart` also gets the
// `TransactionType`/`Recurrence` enums AND their extensions. Extensions are
// only in scope when their defining library is imported/exported.
export 'recurrence.dart';
export 'transaction_type.dart';

/// A single money entry. Immutable — edits produce a new instance via copyWith.
///
/// Loan fields ([interestPercent], [dueDate]) are only meaningful when [type]
/// is a loan. [recurrence] drives the recurring-entries feature; a `once` entry
/// is a normal single transaction.
class TxnEntry extends Equatable {
  const TxnEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.subCategoryId,
    required this.date,
    this.note = '',
    this.interestPercent,
    this.dueDate,
    this.recurrence = Recurrence.once,
    this.recurrenceStart,
    this.counterparty,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String? subCategoryId;

  /// For loans this is the "date given / taken".
  final DateTime date;
  final String note;

  // ---- Loan-only metadata ----
  final double? interestPercent; // e.g. 2.0 == 2% per month
  final DateTime? dueDate;

  /// Person's name for a loan (they are "just names you type").
  final String? counterparty;

  // ---- Recurring ----
  final Recurrence recurrence;

  /// The date the repeat schedule starts from (defaults to [date]).
  final DateTime? recurrenceStart;

  /// Signed value against cash-in-hand. Used for the net-balance sum.
  double get signed => amount * type.sign;

  bool get isRecurring => recurrence.isRecurring;

  TxnEntry copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? subCategoryId,
    bool clearSubCategory = false,
    DateTime? date,
    String? note,
    double? interestPercent,
    DateTime? dueDate,
    String? counterparty,
    Recurrence? recurrence,
    DateTime? recurrenceStart,
  }) {
    return TxnEntry(
      id: id,
      userId: userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId:
          clearSubCategory ? null : (subCategoryId ?? this.subCategoryId),
      date: date ?? this.date,
      note: note ?? this.note,
      interestPercent: interestPercent ?? this.interestPercent,
      dueDate: dueDate ?? this.dueDate,
      counterparty: counterparty ?? this.counterparty,
      recurrence: recurrence ?? this.recurrence,
      recurrenceStart: recurrenceStart ?? this.recurrenceStart,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.key,
        'amount': amount,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'date': date.toIso8601String(),
        'note': note,
        'interestPercent': interestPercent,
        'dueDate': dueDate?.toIso8601String(),
        'counterparty': counterparty,
        'recurrence': recurrence.key,
        'recurrenceStart': recurrenceStart?.toIso8601String(),
      };

  factory TxnEntry.fromMap(Map<String, dynamic> map) => TxnEntry(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: TransactionTypeX.fromKey(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['categoryId'] as String,
        subCategoryId: map['subCategoryId'] as String?,
        date: DateTime.parse(map['date'] as String),
        note: (map['note'] as String?) ?? '',
        interestPercent: (map['interestPercent'] as num?)?.toDouble(),
        dueDate: map['dueDate'] == null
            ? null
            : DateTime.parse(map['dueDate'] as String),
        counterparty: map['counterparty'] as String?,
        recurrence: RecurrenceX.fromKey(map['recurrence'] as String?),
        recurrenceStart: map['recurrenceStart'] == null
            ? null
            : DateTime.parse(map['recurrenceStart'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amount,
        categoryId,
        subCategoryId,
        date,
        note,
        interestPercent,
        dueDate,
        counterparty,
        recurrence,
        recurrenceStart,
      ];
}
