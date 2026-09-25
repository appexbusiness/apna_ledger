import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/fade_in.dart';
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(transactionsStreamProvider),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  // Greeting + branding
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.hello},',
                          style: TextStyle(color: context.semantic.muted)),
                      const SizedBox(height: 2),
                      Text(user?.displayName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge),
                      const _BrandingLine(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick tools
                  Row(
                    children: [
                      _ToolIcon(
                        icon: Icons.download_outlined,
                        tooltip: l10n.download,
                        onTap: () => _downloadLedger(context, ref),
                      ),
                      _ToolIcon(
                        icon: Icons.calculate_outlined,
                        tooltip: l10n.calculator,
                        onTap: () => context.push('/dashboard/calculator'),
                      ),
                      _ToolIcon(
                        icon: Icons.sticky_note_2_outlined,
                        tooltip: l10n.notes,
                        onTap: () => context.push('/dashboard/notes'),
                      ),
                      _ToolIcon(
                        icon: Icons.savings_outlined,
                        tooltip: l10n.savingsGoals,
                        onTap: () => context.push('/dashboard/goals'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const InternetBanner(),

                  // Total Net Balance (animated hero)
                  BalanceCard(
                    balance: summary.balance,
                    onInfo: () => showAppSheet<void>(
                      context,
                      title: l10n.netBalanceHow,
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(l10n.netBalanceFormula,
                            style: const TextStyle(height: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Four types that justify the balance (tap → filtered history)
                  TypeOverview(summary: summary),
                  const SizedBox(height: 20),

                  // Quick add (blinking dots)
                  Row(
                    children: [
                      Text(l10n.quickAdd,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 6),
                      Text('· ${l10n.tapToAdd}',
                          style: TextStyle(
                              color: context.semantic.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const QuickAddGrid(),
                  const SizedBox(height: 18),

                  // Categories at a glance — tap to expand & add
                  Text(l10n.categories,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  const QuickCategories(),
                  const SizedBox(height: 20),

                  // Streak
                  if (streak > 0) ...[
                    StreakCard(days: streak),
                    const SizedBox(height: 20),
                  ],

                  // Insights (pie + animated bars + period filter)
                  const InsightsSection(),
                  const SizedBox(height: 24),

                  // Ledger history (search + filter + download)
                  SectionHeader(
                    title: l10n.ledgerHistory,
                    action: TextButton(
                      onPressed: () => context.go('/dashboard/transactions'),
                      child: Text(l10n.viewAll),
                    ),
                  ),
                  const LedgerControls(),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    _Empty(l10n: l10n)
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Column(
                          children: [
                            for (final t in filtered.take(8))
                              FadeIn(
                                child: TransactionTile(
                                  txn: t,
                                  category: catsById[t.categoryId],
                                  onTap: () => context.push(
                                      '/dashboard/transaction/view',
                                      extra: t),
                                ),
                              ),
                            if (filtered.length > 8)
                              TextButton(
                                onPressed: () =>
                                    context.go('/dashboard/transactions'),
                                child: Text(
                                    '${l10n.viewAll} (${filtered.length})'),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _downloadLedger(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  await runLedgerDownload(
    context,
    ref,
    source: ref.read(filteredTransactionsProvider),
    fileBase: 'apna-ledger-history',
    title: l10n.ledgerHistory,
  );
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox(
                height: 46,
                child: Icon(icon, color: primary, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandingLine extends StatelessWidget {
  const _BrandingLine();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Image.asset('assets/branding/logo_512.png', height: 18, width: 18),
          const SizedBox(width: 6),
          Text('${l10n.appName} · ${l10n.poweredBy}',
              style: TextStyle(
                  color: context.semantic.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: context.semantic.muted),
          const SizedBox(height: 16),
          Text(l10n.noTransactions,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            l10n.noTransactionsHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.semantic.muted),
          ),
        ],
      ),
    );
  }
}
