import '../domain/transaction_type.dart';

/// Passed as go_router `extra` when opening the Add Transaction screen for a
/// NEW entry with some fields pre-filled (from a home quick-card, the
/// calculator's "add as transaction", or "add from this category").
class NewTxnArgs {
  const NewTxnArgs({
    this.type,
    this.amount,
    this.categoryId,
    this.subCategoryId,
  });
  final TransactionType? type;
  final double? amount;
  final String? categoryId;
  final String? subCategoryId;
}
