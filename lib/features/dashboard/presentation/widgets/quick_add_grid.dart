import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/new_txn_args.dart';
import '../../../transactions/presentation/txn_ui.dart';

/// Four floating 3D action orbs. Tapping one opens Add Transaction with that
/// type pre-selected, so logging is one tap away.
class QuickAddGrid extends StatelessWidget {
  const QuickAddGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, t) in TransactionType.values.indexed)
          Expanded(
            child: Entrance(
              index: i,
              child: _QuickOrb(type: t, phase: i / 4),
            ),
          ),
      ],
    );
  }
}

class _QuickOrb extends StatelessWidget {
  const _QuickOrb({required this.type, required this.phase});
  final TransactionType type;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = context.semantic.byTypeKey(type.key);
    return Pressable(
      onTap: () => context.push(
        '/dashboard/transaction',
        extra: NewTxnArgs(type: type),
      ),
      pressedScale: 0.88,
      semanticLabel: type.label(l10n),
      child: Column(
        children: [
          Floating(
            amplitude: 3,
            phase: phase,
            tilt: 0.04,
            child: Icon3D(glyph: type.glyph, size: 54),
          ),
          const SizedBox(height: 8),
          Text(
            type.label(l10n),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
