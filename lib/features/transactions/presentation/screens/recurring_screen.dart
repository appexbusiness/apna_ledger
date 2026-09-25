import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_tile.dart';

/// Lists all recurring entries grouped by frequency, so the user can review or
/// modify anything set to repeat.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recurring = ref.watch(recurringTransactionsProvider);
    final catsById = ref.watch(categoryByIdProvider);

    String header(Recurrence r) {
      switch (r) {
        case Recurrence.daily:
          return l10n.daily;
        case Recurrence.weekly:
          return l10n.weekly;
        case Recurrence.monthly:
          return l10n.monthly;
        case Recurrence.yearly:
          return l10n.yearly;
        case Recurrence.once:
          return l10n.oneTime;
      }
    }

    final byFreq = <Recurrence, List<TxnEntry>>{};
    for (final t in recurring) {
      byFreq.putIfAbsent(t.recurrence, () => []).add(t);
    }
    final order = [
      Recurrence.daily,
      Recurrence.weekly,
      Recurrence.monthly,
      Recurrence.yearly,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringEntries)),
      body: SafeArea(
        child: recurring.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 56, color: context.semantic.muted),
                      const SizedBox(height: 14),
                      Text(l10n.noRecurring,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      for (final freq in order)
                        if ((byFreq[freq] ?? []).isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                            child: Text(
                              header(freq),
                              style: TextStyle(
                                color: context.semantic.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Column(
                                children: [
                                  for (final t in byFreq[freq]!)
                                    TransactionTile(
                                      txn: t,
                                      category: catsById[t.categoryId],
                                      onTap: () => context.push(
                                          '/dashboard/transaction/view',
                                          extra: t),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
