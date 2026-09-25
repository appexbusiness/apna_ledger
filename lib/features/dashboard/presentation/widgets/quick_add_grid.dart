import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/blinking_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/new_txn_args.dart';

/// Four eye-catching quick-add cards. Tapping one opens Add Transaction with
/// that type pre-selected, so logging is one tap away.
class QuickAddGrid extends StatelessWidget {
  const QuickAddGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_QuickItem>[
      _QuickItem(TransactionType.income, l10n.income, Icons.south_west_rounded),
      _QuickItem(
          TransactionType.expense, l10n.expense, Icons.north_east_rounded),
      _QuickItem(
          TransactionType.loanGiven, l10n.loanGiven, Icons.call_made_rounded),
      _QuickItem(TransactionType.loanTaken, l10n.loanTaken,
          Icons.call_received_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 4-across on wide screens, 2×2 on phones.
        final cols = constraints.maxWidth > 520 ? 4 : 2;
        final spacing = 12.0;
        final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _QuickCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _QuickItem {
  const _QuickItem(this.type, this.label, this.icon);
  final TransactionType type;
  final String label;
  final IconData icon;
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    final color = context.semantic.byTypeKey(item.type.key);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/dashboard/transaction',
            extra: NewTxnArgs(type: item.type)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              BlinkingDot(color: color),
            ],
          ),
        ),
      ),
    );
  }
}
