import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';
import '../widgets/ledger_controls.dart';
import '../widgets/transaction_tile.dart';

/// Full ledger history: search + filter + export, grouped by day, swipe to
/// edit/delete, tap for details.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final txnsAsync = ref.watch(transactionsStreamProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final catsById = ref.watch(categoryByIdProvider);
    final groups = _groupByDay(filtered);
    final net = filtered.fold<double>(0, (s, t) => s + t.signed);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(transactionsStreamProvider),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ScreenHeader(
                        title: l10n.ledgerHistory,
                        subtitle: '${filtered.length} ${l10n.totalTransactions}',
                        // Pops a pushed route if there is one (reached from a
                        // category); otherwise falls back to Home.
                        onBack: () => context.canPop()
                            ? context.pop()
                            : context.go('/dashboard'),
                        actions: [
                          IconOrb(
                            icon: Icons.event_repeat_rounded,
                            tooltip: l10n.recurringEntries,
                            onTap: () => context.push('/dashboard/recurring'),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Entrance(
                              child: _NetStrip(
                                count: filtered.length,
                                net: net,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Entrance(index: 1, child: LedgerControls()),
                          ],
                        ),
                      ),
                    ),
                    ...txnsAsync.when(
                      loading: () => [
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                          sliver: SliverToBoxAdapter(child: LedgerSkeleton()),
                        ),
                      ],
                      error: (e, _) => [
                        SliverToBoxAdapter(
                          child: ErrorState(
                            onRetry: () =>
                                ref.invalidate(transactionsStreamProvider),
                          ),
                        ),
                      ],
                      data: (all) {
                        if (all.isEmpty) {
                          return [
                            SliverToBoxAdapter(
                              child: EmptyState(
                                glyph: FinGlyph.wallet,
                                title: l10n.noTransactions,
                                message: l10n.noTransactionsHint,
                                actionLabel: l10n.addTransaction,
                                onAction: () =>
                                    context.push('/dashboard/transaction'),
                              ),
                            ),
                          ];
                        }
                        if (groups.isEmpty) {
                          return [
                            SliverToBoxAdapter(
                              child: EmptyState(
                                glyph: FinGlyph.search,
                                title: l10n.exportEmpty,
                                compact: true,
                              ),
                            ),
                          ];
                        }
                        return [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  Icon(Icons.swipe_rounded,
                                      size: 15,
                                      color: context.semantic.muted,),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.swipeHint,
                                      style: TextStyle(
                                        color: context.semantic.muted,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                            sliver: SliverList.builder(
                              itemCount: groups.length,
                              itemBuilder: (context, gi) {
                                final group = groups[gi];
                                return _DayGroupCard(
                                  label: _dayLabel(group.day, l10n),
                                  net: group.net,
                                  index: gi,
                                  children: [
                                    for (var i = 0; i < group.items.length; i++)
                                      LedgerRow(
                                        txn: group.items[i],
                                        category: catsById[
                                            group.items[i].categoryId],
                                        index: i,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime day, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    return '${Formatters.weekday(day)}, ${Formatters.fullDate(day)}';
  }

  static List<_DayGroup> _groupByDay(List<TxnEntry> txns) {
    final map = <DateTime, List<TxnEntry>>{};
    for (final t in txns) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final groups = map.entries
        .map(
          (e) => _DayGroup(
            day: e.key,
            items: e.value,
            net: e.value.fold<double>(0, (s, t) => s + t.signed),
          ),
        )
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

class _DayGroupCard extends StatelessWidget {
  const _DayGroupCard({
    required this.label,
    required this.net,
    required this.children,
    required this.index,
  });

  final String label;
  final double net;
  final List<Widget> children;
  final int index;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final netColor = net >= 0 ? semantic.income : semantic.expense;
    return Entrance(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: netColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: semantic.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: netColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      Formatters.signedWhole(net),
                      style: TextStyle(
                        color: netColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Surface3D(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact summary of the current (filtered) view: count + net movement.
class _NetStrip extends StatelessWidget {
  const _NetStrip({required this.count, required this.net});
  final int count;
  final double net;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    final color = net >= 0 ? semantic.income : semantic.expense;
    return HeroPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.netFlow,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUp(
                    value: net,
                    format: Formatters.signedSmart,
                    style: AppTypography.money(
                      size: 26,
                      color: net >= 0 ? const Color(0xFF6EE7A8) : const Color(0xFFFF9C9C),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${l10n.totalTransactions}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon3D(glyph: net >= 0 ? FinGlyph.income : FinGlyph.expense,
              color: color, size: 50,),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
