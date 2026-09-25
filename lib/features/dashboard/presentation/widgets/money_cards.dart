import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tools/presentation/goals_providers.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// This month's savings rate as a glowing ring, with a plain-language
/// verdict. Purely derived from [MoneySummary] (income vs spending).
class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({super.key, required this.summary});
  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final income = summary.income;
    final expense = summary.expense;
    final empty = income <= 0 && expense <= 0;
    final rate = income > 0 ? (income - expense) / income : -1.0;

    final (Color color, String verdict) = empty
        ? (semantic.muted, l10n.noData)
        : rate >= 0.3
            ? (AppColors.income, l10n.healthGreat)
            : rate >= 0.1
                ? (AppColors.primary, l10n.healthGood)
                : rate >= 0
                    ? (AppColors.warning, l10n.healthWatch)
                    : (AppColors.expense, l10n.healthLow);

    return Surface3D(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          RingProgress(
            value: empty ? 0 : rate.clamp(0.0, 1.0),
            color: color,
            size: 92,
            stroke: 11,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  empty
                      ? '—'
                      : '${(rate.clamp(-9.99, 1.0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                Text(
                  l10n.saved,
                  style: TextStyle(
                    color: semantic.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.financialHealth,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.savingsRate} · ${l10n.thisMonth}',
                  style: TextStyle(
                    color: semantic.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    verdict,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
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

/// Last six months of income vs spending as paired gradient bars.
class MonthlyMovementCard extends ConsumerStatefulWidget {
  const MonthlyMovementCard({super.key});

  @override
  ConsumerState<MonthlyMovementCard> createState() =>
      _MonthlyMovementCardState();
}

class _MonthlyMovementCardState extends ConsumerState<MonthlyMovementCard> {
  bool _grown = false;

  @override
  void initState() {
    super.initState();
    // Start flat, then let fl_chart animate the bars up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final txns = ref.watch(transactionsStreamProvider).value ?? const [];
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    final income = List<double>.filled(6, 0);
    final spend = List<double>.filled(6, 0);
    for (final t in txns) {
      final idx = months.indexWhere(
        (m) => m.year == t.date.year && m.month == t.date.month,
      );
      if (idx < 0) continue;
      if (t.type == TransactionType.income) income[idx] += t.amount;
      if (t.type == TransactionType.expense) spend[idx] += t.amount;
    }
    final maxY = [...income, ...spend].fold<double>(0, math.max);

    BarChartRodData rod(double v, Color c) => BarChartRodData(
          toY: _grown ? v : 0,
          width: 11,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.darken(c, 0.06), AppColors.lighten(c, 0.12)],
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY <= 0 ? 1 : maxY * 1.1,
            color: c.withValues(alpha: 0.06),
          ),
        );

    return Surface3D(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon3D(glyph: FinGlyph.calendar, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.monthlyMovement,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _Legend(color: semantic.income, label: l10n.income),
              const SizedBox(width: 10),
              _Legend(color: semantic.expense, label: l10n.spending),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: maxY <= 0
                ? Center(
                    child: Text(
                      l10n.noData,
                      style: TextStyle(color: semantic.muted),
                    ),
                  )
                : BarChart(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    BarChartData(
                      maxY: maxY * 1.1,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: semantic.border.withValues(alpha: 0.6),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= months.length) {
                                return const SizedBox.shrink();
                              }
                              final current = i == months.length - 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(months[i]),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: current
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: current ? null : semantic.muted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 12,
                          getTooltipColor: (_) => AppColors.heroTop,
                          getTooltipItem: (group, _, rod, rodIndex) =>
                              BarTooltipItem(
                            Formatters.moneySmart(rod.toY),
                            TextStyle(
                              color: rodIndex == 0
                                  ? const Color(0xFF6EE7A8)
                                  : const Color(0xFFFF9C9C),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < 6; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 4,
                            barRods: [
                              rod(income[i], semantic.income),
                              rod(spend[i], semantic.expense),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.semantic.muted,
          ),
        ),
      ],
    );
  }
}

/// Money given vs money taken this month on one split bar.
class GivenTakenCard extends ConsumerWidget {
  const GivenTakenCard({super.key, required this.summary});
  final MoneySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    void open(TransactionType t) {
      ref.read(txnFilterProvider.notifier).state = TxnFilter(types: {t});
      context.go('/dashboard/transactions');
    }

    Widget side(TransactionType t, FinGlyph g, double v, bool end) {
      final c = semantic.byTypeKey(t.key);
      return Expanded(
        child: Pressable(
          onTap: () => open(t),
          child: Row(
            mainAxisAlignment:
                end ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!end) ...[
                Icon3D(glyph: g, size: 36, coin: false),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      t == TransactionType.loanGiven
                          ? l10n.loanGiven
                          : l10n.loanTaken,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: semantic.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CountUp(
                        value: v,
                        format: Formatters.moneySmart,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (end) ...[
                const SizedBox(width: 8),
                Icon3D(glyph: g, size: 36, coin: false),
              ],
            ],
          ),
        ),
      );
    }

    return Surface3D(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.givenVsTaken} · ${l10n.thisMonth}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              side(
                TransactionType.loanGiven,
                FinGlyph.given,
                summary.loanGiven,
                false,
              ),
              const SizedBox(width: 12),
              side(
                TransactionType.loanTaken,
                FinGlyph.taken,
                summary.loanTaken,
                true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SplitBar(
            left: summary.loanGiven,
            right: summary.loanTaken,
            leftColor: semantic.loanGiven,
            rightColor: semantic.loanTaken,
          ),
        ],
      ),
    );
  }
}

/// Top savings goals with animated progress; hidden when there are none.
class GoalsPreview extends ConsumerWidget {
  const GoalsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goals = ref.watch(goalsProvider);
    if (goals.isEmpty) return const SizedBox.shrink();
    final top = [...goals]..sort((a, b) => b.progress.compareTo(a.progress));
    const pink = Color(0xFFEC4899);

    return Surface3D(
      onTap: () => context.push('/dashboard/goals'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon3D(glyph: FinGlyph.goals, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.savingsGoals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.semantic.muted),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, g) in top.take(3).indexed) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  g.reached
                      ? l10n.goalReached
                      : '${(g.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: g.reached ? context.semantic.income : pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GlowBar(
              value: g.progress,
              color: g.reached ? context.semantic.income : pink,
              height: 8,
              delay: Duration(milliseconds: 120 * i),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
