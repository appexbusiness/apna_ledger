import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/services/export_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';

/// Shared CSV export helper.
final exportServiceProvider = Provider((ref) => const ExportService());

/// Convenience: current signed-in user id (empty when logged out).
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authControllerProvider)?.id ?? '';
});

/// Live list of the user's transactions (newest first).
final transactionsStreamProvider =
    StreamProvider.autoDispose<List<TxnEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId.isEmpty) return const Stream.empty();
  return ref.watch(transactionRepositoryProvider).watch(userId);
});

/// Aggregated totals for the current month + all-time net balance.
class MoneySummary {
  const MoneySummary({
    this.income = 0,
    this.expense = 0,
    this.loanGiven = 0,
    this.loanTaken = 0,
    this.balance = 0,
  });

  final double income;
  final double expense;
  final double loanGiven;
  final double loanTaken;

  /// All-time net cash position (income + loanTaken − expense − loanGiven).
  final double balance;

  double totalFor(String typeKey) {
    switch (typeKey) {
      case 'income':
        return income;
      case 'expense':
        return expense;
      case 'loanGiven':
        return loanGiven;
      case 'loanTaken':
        return loanTaken;
      default:
        return 0;
    }
  }
}

final monthSummaryProvider = Provider.autoDispose<MoneySummary>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final now = DateTime.now();
  double income = 0, expense = 0, loanGiven = 0, loanTaken = 0, balance = 0;
  for (final t in txns) {
    balance += t.signed;
    if (t.date.year == now.year && t.date.month == now.month) {
      switch (t.type) {
        case TransactionType.income:
          income += t.amount;
          break;
        case TransactionType.expense:
          expense += t.amount;
          break;
        case TransactionType.loanGiven:
          loanGiven += t.amount;
          break;
        case TransactionType.loanTaken:
          loanTaken += t.amount;
          break;
      }
    }
  }
  return MoneySummary(
    income: income,
    expense: expense,
    loanGiven: loanGiven,
    loanTaken: loanTaken,
    balance: balance,
  );
});

/// Expense totals grouped by categoryId for the current month (for the pie).
final expenseByCategoryProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final now = DateTime.now();
  final map = <String, double>{};
  for (final t in txns) {
    if (!t.type.isExpense) continue;
    if (t.date.year != now.year || t.date.month != now.month) continue;
    map.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
  }
  return map;
});

// ---------------------------------------------------------------------------
// Filtering + search for the ledger-history views (and CSV export).
// ---------------------------------------------------------------------------

class TxnFilter {
  const TxnFilter({
    this.query = '',
    this.types = const {},
    this.categoryId,
    this.subCategoryId,
    this.from,
    this.to,
  });

  final String query;

  /// Empty set == all types.
  final Set<TransactionType> types;
  final String? categoryId;
  final String? subCategoryId;
  final DateTime? from;
  final DateTime? to;

  bool get isActive =>
      query.isNotEmpty ||
      types.isNotEmpty ||
      categoryId != null ||
      subCategoryId != null ||
      from != null ||
      to != null;

  TxnFilter copyWith({
    String? query,
    Set<TransactionType>? types,
    String? categoryId,
    String? subCategoryId,
    bool clearCategory = false,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
  }) {
    return TxnFilter(
      query: query ?? this.query,
      types: types ?? this.types,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subCategoryId:
          clearCategory ? null : (subCategoryId ?? this.subCategoryId),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }
}

/// The active ledger-history filter (search box + chips). Autodispose off so it
/// survives tab switches.
final txnFilterProvider =
    StateProvider<TxnFilter>((ref) => const TxnFilter());

bool _matches(TxnEntry t, TxnFilter f, String? categoryName) {
  if (f.types.isNotEmpty && !f.types.contains(t.type)) return false;
  if (f.categoryId != null && t.categoryId != f.categoryId) return false;
  if (f.subCategoryId != null && t.subCategoryId != f.subCategoryId) {
    return false;
  }
  if (f.from != null && t.date.isBefore(f.from!)) return false;
  if (f.to != null && t.date.isAfter(f.to!)) return false;
  if (f.query.isNotEmpty) {
    final q = f.query.toLowerCase();
    final hay = '${t.note} ${t.counterparty ?? ''} ${categoryName ?? ''} '
            '${t.amount.toStringAsFixed(0)}'
        .toLowerCase();
    if (!hay.contains(q)) return false;
  }
  return true;
}

/// Transactions after the active filter is applied (newest first).
final filteredTransactionsProvider =
    Provider.autoDispose<List<TxnEntry>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final filter = ref.watch(txnFilterProvider);
  if (!filter.isActive) return txns;
  final cats = ref.watch(categoryByIdProvider);
  return txns
      .where((t) => _matches(t, filter, cats[t.categoryId]?.name))
      .toList();
});

/// Consecutive-day logging streak (today counts; a fully missed day breaks it).
final streakProvider = Provider.autoDispose<int>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  if (txns.isEmpty) return 0;
  final days = txns
      .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
      .toSet();
  final now = DateTime.now();
  var cursor = DateTime(now.year, now.month, now.day);
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
});

/// Transaction count per categoryId.
final categoryCountProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final m = <String, int>{};
  for (final t in txns) {
    m[t.categoryId] = (m[t.categoryId] ?? 0) + 1;
  }
  return m;
});

/// Transaction count per subCategoryId.
final subCategoryCountProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final m = <String, int>{};
  for (final t in txns) {
    final s = t.subCategoryId;
    if (s != null) m[s] = (m[s] ?? 0) + 1;
  }
  return m;
});

/// All-time income/expense totals per categoryId (loans excluded — matches the
/// category breakdown UI which shows only income vs expense).
final categoryTotalsProvider =
    Provider.autoDispose<Map<String, ({double income, double expense})>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final map = <String, ({double income, double expense})>{};
  for (final t in txns) {
    if (t.type.isLoan) continue;
    final cur = map[t.categoryId] ?? (income: 0.0, expense: 0.0);
    map[t.categoryId] = t.type.isIncome
        ? (income: cur.income + t.amount, expense: cur.expense)
        : (income: cur.income, expense: cur.expense + t.amount);
  }
  return map;
});

/// All-time income/expense totals per subCategoryId.
final subCategoryTotalsProvider =
    Provider.autoDispose<Map<String, ({double income, double expense})>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  final map = <String, ({double income, double expense})>{};
  for (final t in txns) {
    if (t.type.isLoan || t.subCategoryId == null) continue;
    final key = t.subCategoryId!;
    final cur = map[key] ?? (income: 0.0, expense: 0.0);
    map[key] = t.type.isIncome
        ? (income: cur.income + t.amount, expense: cur.expense)
        : (income: cur.income, expense: cur.expense + t.amount);
  }
  return map;
});

/// All recurring entries (recurrence != once), newest first.
final recurringTransactionsProvider =
    Provider.autoDispose<List<TxnEntry>>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? const [];
  return txns.where((t) => t.isRecurring).toList();
});

/// Write actions for transactions.
final transactionActionsProvider = Provider((ref) => TransactionActions(ref));

class TransactionActions {
  TransactionActions(this._ref);
  final Ref _ref;

  Future<void> save(TxnEntry entry) async {
    await _ref.read(transactionRepositoryProvider).upsert(entry);
    _ref.invalidate(transactionsStreamProvider);
  }

  Future<void> delete(String id) async {
    final userId = _ref.read(currentUserIdProvider);
    await _ref.read(transactionRepositoryProvider).delete(userId, id);
    _ref.invalidate(transactionsStreamProvider);
  }

  /// Move a sub-category's entries when it is removed (delete or reassign).

  /// When a sub-category is removed, either delete its entries or move them up
  /// to the parent category (clearing the sub-category). Returns how many
  /// entries were affected.
  Future<int> handleSubCategoryRemoval({
    required String categoryId,
    required String subId,
    required bool deleteEntries,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    final repo = _ref.read(transactionRepositoryProvider);
    final all = _ref.read(transactionsStreamProvider).value ?? const [];
    final affected = all
        .where((t) => t.categoryId == categoryId && t.subCategoryId == subId)
        .toList();
    for (final t in affected) {
      if (deleteEntries) {
        await repo.delete(userId, t.id);
      } else {
        await repo.upsert(t.copyWith(clearSubCategory: true));
      }
    }
    return affected.length;
  }
}
