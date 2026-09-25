import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';
import '../txn_ui.dart';
import '../widgets/transaction_tile.dart';

/// Lists all recurring entries grouped by frequency, so the user can review or
/// modify anything set to repeat.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  static const _order = [
    Recurrence.daily,
    Recurrence.weekly,
    Recurrence.monthly,
    Recurrence.yearly,
  ];

  static const _colors = {
    Recurrence.daily: Color(0xFF0EA5E9),
    Recurrence.weekly: AppColors.primary,
    Recurrence.monthly: AppColors.loanTaken,
    Recurrence.yearly: Color(0xFFE9A20F),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recurring = ref.watch(recurringTransactionsProvider);
    final catsById = ref.watch(categoryByIdProvider);

    final byFreq = <Recurrence, List<TxnEntry>>{};
    for (final t in recurring) {
      byFreq.putIfAbsent(t.recurrence, () => []).add(t);
    }

    return Scaffold(
      body: AmbientBackground(
        tint: AppColors.loanTaken,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  ScreenHeader(
                    title: l10n.recurringEntries,
                    subtitle: '${recurring.length} ${l10n.recurring}',
                    onBack: () => context.pop(),
                  ),
                  if (recurring.isEmpty)
                    EmptyState(
                      glyph: FinGlyph.recurring,
                      title: l10n.noRecurring,
                      actionLabel: l10n.addTransaction,
                      onAction: () => context.push('/dashboard/transaction'),
                    )
                  else ...[
                    // Frequency overview tiles.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          for (final f in _order) ...[
                            Expanded(
                              child: Entrance(
                                index: _order.indexOf(f),
                                child: _FreqTile(
                                  label: f.label(l10n),
                                  count: byFreq[f]?.length ?? 0,
                                  color: _colors[f]!,
                                ),
                              ),
                            ),
                            if (f != _order.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    for (final freq in _order)
                      if ((byFreq[freq] ?? []).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: Entrance(
                            index: _order.indexOf(freq) + 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon3D(
                                      glyph: FinGlyph.recurring,
                                      color: _colors[freq],
                                      size: 30,
                                      style: Icon3DStyle.soft,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      freq.label(l10n),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      Formatters.signedSmart(
                                        byFreq[freq]!.fold<double>(
                                            0, (s, t) => s + t.signed,),
                                      ),
                                      style: TextStyle(
                                        color: context.semantic.muted,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Surface3D(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      for (var i = 0;
                                          i < byFreq[freq]!.length;
                                          i++)
                                        LedgerRow(
                                          txn: byFreq[freq]![i],
                                          category: catsById[
                                              byFreq[freq]![i].categoryId],
                                          index: i,
                                        ),
                                    ],
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
          ),
        ),
      ),
    );
  }
}

class _FreqTile extends StatelessWidget {
  const _FreqTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Surface3D(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      radius: 18,
      tint: active ? color : null,
      elevation: active ? 0.7 : 0.5,
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: active ? Colors.white : context.semantic.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active
                  ? Colors.white.withValues(alpha: 0.85)
                  : context.semantic.muted,
            ),
          ),
        ],
      ),
    );
  }
}
