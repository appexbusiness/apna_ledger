import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/txn_ui.dart';
import 'category_pie.dart';

enum InsightPeriod { day, week, month, year }

/// Insights: 3D pillars per money type + a 3D spending-by-category donut,
/// with a Day / Week / Month / Year switch.
class InsightsSection extends ConsumerStatefulWidget {
  const InsightsSection({super.key});

  @override
  ConsumerState<InsightsSection> createState() => _InsightsSectionState();
}

class _InsightsSectionState extends ConsumerState<InsightsSection> {
  InsightPeriod _period = InsightPeriod.month;

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_period) {
      case InsightPeriod.day:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case InsightPeriod.week:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return !d.isBefore(start);
      case InsightPeriod.month:
        return d.year == now.year && d.month == now.month;
      case InsightPeriod.year:
        return d.year == now.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final txns = ref.watch(transactionsStreamProvider).value ?? const [];
    final catsById = ref.watch(categoryByIdProvider);
    final semantic = context.semantic;

    final spendingByCat = <String, double>{};
    final totals = <TransactionType, double>{
      for (final t in TransactionType.values) t: 0,
    };
    for (final t in txns) {
      if (!_inPeriod(t.date)) continue;
      totals[t.type] = (totals[t.type] ?? 0) + t.amount;
      if (t.type.isExpense) {
        spendingByCat.update(
          t.categoryId,
          (v) => v + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    String periodLabel(InsightPeriod p) => switch (p) {
          InsightPeriod.day => l10n.periodDay,
          InsightPeriod.week => l10n.periodWeek,
          InsightPeriod.month => l10n.periodMonth,
          InsightPeriod.year => l10n.periodYear,
        };

    return Surface3D(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon3D(glyph: FinGlyph.analytics, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.insights,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedPills<InsightPeriod>(
            options: InsightPeriod.values,
            value: _period,
            labels: periodLabel,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: Pillars3D(
              key: ValueKey(_period),
              valueLabel: Formatters.moneySmart,
              data: [
                for (final t in TransactionType.values)
                  ChartDatum(
                    label: t.label(l10n),
                    value: totals[t] ?? 0,
                    color: semantic.byTypeKey(t.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (spendingByCat.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.noData,
                  style: TextStyle(
                    color: semantic.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Divider(color: semantic.border),
            const SizedBox(height: 12),
            Text(
              l10n.spendingByCategory,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: AppMotion.medium,
              child: CategoryPie(
                key: ValueKey(_period),
                totals: spendingByCat,
                categories: catsById,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
