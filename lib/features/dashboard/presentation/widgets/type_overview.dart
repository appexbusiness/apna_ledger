import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/txn_ui.dart';

/// The four money types that justify the net balance, as raised 3D tiles
/// with counting figures. Tapping a tile opens the ledger filtered to it.
class TypeOverview extends ConsumerWidget {
  const TypeOverview({super.key, required this.summary});
  final MoneySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(TransactionType t) {
      ref.read(txnFilterProvider.notifier).state = TxnFilter(types: {t});
      context.go('/dashboard/transactions');
    }

    // Fixed-height tiles (mainAxisExtent) so content never overflows,
    // regardless of screen width or the device's text-scale setting.
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 84,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      children: [
        for (final (i, t) in TransactionType.values.indexed)
          Entrance(
            index: i,
            child: _Tile(
              type: t,
              value: summary.totalFor(t.key),
              onTap: () => open(t),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.type, required this.value, required this.onTap});
  final TransactionType type;
  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = context.semantic.byTypeKey(type.key);
    return Surface3D(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Icon3D(glyph: type.glyph, size: 40, coin: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.semantic.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUp(
                    value: value,
                    format: Formatters.moneySmart,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.semantic.muted,
          ),
        ],
      ),
    );
  }
}
