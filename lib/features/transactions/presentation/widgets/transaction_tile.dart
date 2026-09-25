import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';
import '../screens/transaction_detail_screen.dart';

/// A single ledger row: 3D category icon (with a repeat badge for recurring
/// entries), name + sub-category/person/note, the signed amount coloured by
/// type, and Day · Time.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.txn,
    required this.category,
    this.onTap,
  });

  final TxnEntry txn;
  final Category? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final color = semantic.byTypeKey(txn.type.key);
    final catColor = AppColors.chartFor(category?.colorIndex ?? 0);
    final icon = category != null
        ? iconFromCode(category!.iconCode)
        : Icons.category_outlined;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon3D(
                    icon: icon,
                    color: catColor,
                    size: 46,
                    style: Icon3DStyle.soft,
                  ),
                  // Type marker: tiny arrow chip in the type colour.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.surfaces.card,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        txn.isRecurring
                            ? Icons.repeat_rounded
                            : _typeIcon(txn.type),
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: semantic.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      Formatters.signedSmart(txn.type.sign * txn.amount),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${Formatters.weekday(txn.date)} · ${Formatters.time(txn.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: semantic.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(TransactionType t) {
    switch (t) {
      case TransactionType.income:
        return Icons.south_west_rounded;
      case TransactionType.expense:
        return Icons.north_east_rounded;
      case TransactionType.loanGiven:
        return Icons.call_made_rounded;
      case TransactionType.loanTaken:
        return Icons.call_received_rounded;
    }
  }

  String _subLabel() {
    final subName = category?.subCategories
        .where((s) => s.id == txn.subCategoryId)
        .map((s) => s.name)
        .firstOrNull;
    final date = Formatters.dayMonth(txn.date);
    final parts = <String>[
      date,
      if (subName != null && subName.isNotEmpty) subName,
      if (txn.counterparty != null && txn.counterparty!.isNotEmpty)
        txn.counterparty!,
      if (txn.note.isNotEmpty) txn.note,
    ];
    return parts.join(' · ');
  }
}

/// A [TransactionTile] with the standard ledger gestures:
/// tap → details sheet, swipe right → edit, swipe left → delete (confirmed).
class LedgerRow extends ConsumerWidget {
  const LedgerRow({
    super.key,
    required this.txn,
    required this.category,
    this.index = 0,
  });

  final TxnEntry txn;
  final Category? category;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    return Entrance(
      index: index,
      offset: 12,
      child: Dismissible(
        key: ValueKey('ledger-${txn.id}'),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.3,
          DismissDirection.endToStart: 0.3,
        },
        background: _SwipeBg(
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.edit_rounded,
          label: l10n.edit,
          alignLeft: true,
        ),
        secondaryBackground: _SwipeBg(
          color: semantic.expense,
          icon: Icons.delete_rounded,
          label: l10n.delete,
          alignLeft: false,
        ),
        confirmDismiss: (dir) async {
          AppHaptics.medium();
          if (dir == DismissDirection.startToEnd) {
            context.push('/dashboard/transaction', extra: txn);
          } else {
            await confirmDeleteTransaction(context, ref, txn, category?.name);
          }
          // The list rebuilds from the provider; never let Dismissible
          // remove the row itself.
          return false;
        },
        child: TransactionTile(
          txn: txn,
          category: category,
          onTap: () => showTransactionDetailSheet(context, txn),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon3D(icon: icon, color: color, size: 34),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
        ),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignLeft ? content : content.reversed.toList(),
      ),
    );
  }
}
