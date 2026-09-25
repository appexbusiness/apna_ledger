import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// The four money types that justify the net balance. Rolling numbers; tapping
/// a tile opens the ledger history filtered to that type.
class TypeOverview extends ConsumerWidget {
  const TypeOverview({super.key, required this.summary});
  final MoneySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tiles = <_OverviewTile>[
      _OverviewTile(TransactionType.income, l10n.income, summary.income),
      _OverviewTile(TransactionType.expense, l10n.spending, summary.expense),
      _OverviewTile(
          TransactionType.loanGiven, l10n.loanGiven, summary.loanGiven),
      _OverviewTile(
          TransactionType.loanTaken, l10n.loanTaken, summary.loanTaken),
    ];

    void open(TransactionType t) {
      ref.read(txnFilterProvider.notifier).state = TxnFilter(types: {t});
      context.go('/dashboard/transactions');
    }

    // Fixed-height tiles (mainAxisExtent) so content never overflows,
    // regardless of screen width or the device's text-scale setting.
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 72,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        for (final t in tiles) _Tile(tile: t, onTap: () => open(t.type)),
      ],
    );
  }
}

class _OverviewTile {
  const _OverviewTile(this.type, this.label, this.value);
  final TransactionType type;
  final String label;
  final double value;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.onTap});
  final _OverviewTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.semantic.byTypeKey(tile.type.key);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: 0.65), width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                height: 9,
                width: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tile.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: context.semantic.muted, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedMoney(
                        tile.value,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: context.semantic.muted),
            ],
          ),
        ),
      ),
    );
  }
}
