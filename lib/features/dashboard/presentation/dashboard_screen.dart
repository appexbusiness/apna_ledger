import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/internet_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../categories/presentation/category_providers.dart';
import '../../transactions/presentation/ledger_export.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../../transactions/presentation/widgets/ledger_controls.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import 'widgets/balance_card.dart';
import 'widgets/insights_section.dart';
import 'widgets/money_cards.dart';
import 'widgets/quick_add_grid.dart';
import 'widgets/quick_categories.dart';
import 'widgets/streak_card.dart';
import 'widgets/type_overview.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider);
    final summary = ref.watch(monthSummaryProvider);
    final catsById = ref.watch(categoryByIdProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final streak = ref.watch(streakProvider);
    final loading = ref.watch(transactionsStreamProvider).isLoading;

    var i = 0;
    Widget step(Widget child) => Entrance(index: i++, child: child);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(transactionsStreamProvider),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
                  children: [
                    step(_Greeting(name: user?.displayName ?? '')),
                    const SizedBox(height: 16),
                    const InternetBanner(),

                    // Total Net Balance (animated hero)
                    step(
                      BalanceCard(
                        balance: summary.balance,
                        monthIn: summary.income + summary.loanTaken,
                        monthOut: summary.expense + summary.loanGiven,
                        onInfo: () => showAppSheet<void>(
                          context,
                          title: l10n.netBalanceHow,
                          glyph: FinGlyph.wallet,
                          builder: (context, _) => _BalanceFormula(l10n: l10n),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Four types that justify the balance (tap → history)
                    TypeOverview(summary: summary),
                    const SizedBox(height: 24),

                    // Quick tools
                    step(const _ToolsDock()),
                    const SizedBox(height: 24),

                    // Quick add
                    SectionHeader(
                      title: l10n.quickAdd,
                      subtitle: l10n.tapToAdd,
                    ),
                    const QuickAddGrid(),
                    const SizedBox(height: 24),

                    // Categories at a glance — tap for sub-categories
                    SectionHeader(title: l10n.categories),
                    const QuickCategories(),
                    const SizedBox(height: 24),

                    if (streak > 0) ...[
                      step(StreakCard(days: streak)),
                      const SizedBox(height: 16),
                    ],

                    step(FinancialHealthCard(summary: summary)),
                    const SizedBox(height: 16),
                    step(const InsightsSection()),
                    const SizedBox(height: 16),
                    step(const MonthlyMovementCard()),
                    const SizedBox(height: 16),
                    step(GivenTakenCard(summary: summary)),
                    const SizedBox(height: 16),
                    step(const GoalsPreview()),
                    const SizedBox(height: 24),

                    // Ledger history (search + filter + download)
                    SectionHeader(
                      title: l10n.ledgerHistory,
                      actionLabel: l10n.viewAll,
                      onAction: () => context.go('/dashboard/transactions'),
                    ),
                    const LedgerControls(),
                    const SizedBox(height: 12),
                    if (loading)
                      const Surface3D(child: LedgerSkeleton(rows: 4))
                    else if (filtered.isEmpty)
                      EmptyState(
                        glyph: FinGlyph.wallet,
                        title: l10n.noTransactions,
                        message: l10n.noTransactionsHint,
                        compact: true,
                      )
                    else
                      Surface3D(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            for (final (n, t) in filtered.take(8).indexed)
                              LedgerRow(
                                txn: t,
                                category: catsById[t.categoryId],
                                index: n,
                              ),
                            if (filtered.length > 8)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: SectionHeader(
                                  title: '',
                                  actionLabel:
                                      '${l10n.viewAll} (${filtered.length})',
                                  onAction: () =>
                                      context.go('/dashboard/transactions'),
                                ),
                              ),
                          ],
                        ),
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
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '₹';
    return Row(
      children: [
        Pressable(
          onTap: () => context.go('/dashboard/settings'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentSoft, AppColors.goldDeep],
              ),
              boxShadow: AppSurfaces.glow(AppColors.accent, strength: 0.7),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.heroTop, AppColors.heroBottom],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.hello} 👋',
                style: TextStyle(
                  color: context.semantic.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/branding/logo_512.png', height: 22, width: 22),
            const SizedBox(width: 6),
            Text(
              l10n.appName,
              style: TextStyle(
                color: context.semantic.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Four 3D tool buttons: download, calculator, notes, savings goals.
class _ToolsDock extends ConsumerWidget {
  const _ToolsDock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tools = <(FinGlyph, String, VoidCallback)>[
      (
        FinGlyph.download,
        l10n.download,
        () => runLedgerDownload(
              context,
              ref,
              source: ref.read(filteredTransactionsProvider),
              fileBase: 'apna-ledger-history',
              title: l10n.ledgerHistory,
            ),
      ),
      (
        FinGlyph.calculator,
        l10n.calculator,
        () => context.push('/dashboard/calculator'),
      ),
      (FinGlyph.notes, l10n.notes, () => context.push('/dashboard/notes')),
      (
        FinGlyph.goals,
        l10n.savingsGoals,
        () => context.push('/dashboard/goals'),
      ),
    ];
    return Surface3D(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        children: [
          for (final t in tools)
            Expanded(
              child: Pressable(
                onTap: t.$3,
                pressedScale: 0.9,
                semanticLabel: t.$2,
                child: Column(
                  children: [
                    Icon3D(glyph: t.$1, size: 46),
                    const SizedBox(height: 8),
                    Text(
                      t.$2,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
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

class _BalanceFormula extends StatelessWidget {
  const _BalanceFormula({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    Widget chip(String label, Color c, String sign) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$sign $label',
            style: TextStyle(color: c, fontWeight: FontWeight.w800),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(l10n.income, semantic.income, '+'),
            chip(l10n.loanTaken, semantic.loanTaken, '+'),
            chip(l10n.spending, semantic.expense, '−'),
            chip(l10n.loanGiven, semantic.loanGiven, '−'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.netBalanceFormula,
          style: TextStyle(color: semantic.muted, height: 1.55),
        ),
      ],
    );
  }
}
