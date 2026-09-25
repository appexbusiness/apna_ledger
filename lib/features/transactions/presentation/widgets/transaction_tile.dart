import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';

/// A single ledger row: category icon, name + sub-category/note, amount
/// (coloured by type) and Date · Day · Time.
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

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: catColor, size: 22),
          ),
          if (txn.isRecurring)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.repeat_rounded, size: 12, color: color),
              ),
            ),
        ],
      ),
      title: Text(
        category?.name ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _subLabel(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: semantic.muted, fontSize: 12),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.signedSmart(txn.type.sign * txn.amount),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${Formatters.weekday(txn.date)} · ${Formatters.time(txn.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: semantic.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
