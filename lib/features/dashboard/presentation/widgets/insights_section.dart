import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'category_pie.dart';

enum InsightPeriod { day, week, month, year }

/// Insights: a spending-by-category donut + animated per-type bars, with a
/// Day / Week / Month / Year filter. Replaces the old overview + pie sections.
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
        final start =
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
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

    final spendingByCat = <String, double>{};
    final totals = <TransactionType, double>{
      for (final t in TransactionType.values) t: 0,
    };
    for (final t in txns) {
      if (!_inPeriod(t.date)) continue;
      totals[t.type] = (totals[t.type] ?? 0) + t.amount;
      if (t.type.isExpense) {
        spendingByCat.update(t.categoryId, (v) => v + t.amount,
            ifAbsent: () => t.amount);
      }
    }
    final maxTotal = totals.values.fold<double>(0, (m, v) => v > m ? v : m);

    String label(TransactionType t) {
      switch (t) {
        case TransactionType.income:
          return l10n.income;
        case TransactionType.expense:
          return l10n.spending;
        case TransactionType.loanGiven:
          return l10n.loanGiven;
        case TransactionType.loanTaken:
          return l10n.loanTaken;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.insights,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            // Period filter
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                children: [
                  _chip(l10n.periodDay, InsightPeriod.day),
                  _chip(l10n.periodWeek, InsightPeriod.week),
                  _chip(l10n.periodMonth, InsightPeriod.month),
                  _chip(l10n.periodYear, InsightPeriod.year),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Animated per-type bars
            for (final t in TransactionType.values)
              _Bar(
                label: label(t),
                value: totals[t] ?? 0,
                max: maxTotal,
                color: context.semantic.byTypeKey(t.key),
              ),
            const SizedBox(height: 8),
            if (spendingByCat.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(l10n.noData,
                      style: TextStyle(color: context.semantic.muted)),
                ),
              )
            else ...[
              const Divider(height: 28),
              Text(l10n.spendingByCategory,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              CategoryPie(totals: spendingByCat, categories: catsById),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, InsightPeriod p) {
    return ChoiceChip(
      label: Text(label),
      selected: _period == p,
      onSelected: (_) => setState(() => _period = p),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });
  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(Formatters.moneySmart(value),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: color.withValues(alpha: 0.12),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: frac),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 8, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
