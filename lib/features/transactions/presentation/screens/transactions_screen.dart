import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../../core/widgets/fade_in.dart';
import '../widgets/ledger_controls.dart';
import '../widgets/transaction_tile.dart';

/// Full ledger history: search + filter + export, grouped by day, tap to edit.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final txnsAsync = ref.watch(transactionsStreamProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final catsById = ref.watch(categoryByIdProvider);

    return Scaffold(
      appBar: AppBar(
        // Pops a real pushed route if there is one (reached from a category
        // or Home's ledger card); otherwise falls back to Home — either way
        // "back" always takes the user somewhere sensible.
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/dashboard'),
        ),
        title: Text(l10n.ledgerHistory),
        actions: [
          IconButton(
            tooltip: l10n.recurringEntries,
            onPressed: () => context.push('/dashboard/recurring'),
            icon: const Icon(Icons.repeat_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: txnsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.somethingWrong)),
          data: (all) {
            final groups = _groupByDay(filtered);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    const LedgerControls(),
                    const SizedBox(height: 8),
                    if (all.isEmpty)
                      _EmptyState(l10n: l10n)
                    else if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(l10n.exportEmpty,
                              style: TextStyle(color: context.semantic.muted)),
                        ),
                      )
                    else
                      for (final group in groups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                          child: Row(
                            children: [
                              Text(
                                _dayLabel(group.day),
                                style: TextStyle(
                                  color: context.semantic.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Formatters.signedWhole(group.net),
                                style: TextStyle(
                                  color: group.net >= 0
                                      ? context.semantic.income
                                      : context.semantic.expense,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Column(
                              children: [
                                for (final t in group.items)
                                  FadeIn(
                                    child: TransactionTile(
                                      txn: t,
                                      category: catsById[t.categoryId],
                                      onTap: () => context.push(
                                          '/dashboard/transaction/view',
                                          extra: t),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return Formatters.fullDate(day);
  }

  static List<_DayGroup> _groupByDay(List<TxnEntry> txns) {
    final map = <DateTime, List<TxnEntry>>{};
    for (final t in txns) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final groups = map.entries
        .map((e) => _DayGroup(
              day: e.key,
              items: e.value,
              net: e.value.fold<double>(0, (s, t) => s + t.signed),
            ))
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return groups;
  }
}

class _DayGroup {
  _DayGroup({required this.day, required this.items, required this.net});
  final DateTime day;
  final List<TxnEntry> items;
  final double net;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: context.semantic.muted),
            const SizedBox(height: 16),
            Text(l10n.noTransactions,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(l10n.noTransactionsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.semantic.muted)),
          ],
        ),
      ),
    );
  }
}
