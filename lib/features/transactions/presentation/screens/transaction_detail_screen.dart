import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';

/// Read-only, nicely organised view of a single entry. Editing is explicit —
/// the pencil in the app bar opens the edit form.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.entry});
  final TxnEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(transactionsStreamProvider).value ?? const [];
    // Stay fresh after edits; fall back to the passed entry.
    final txn = all.where((t) => t.id == entry.id).isNotEmpty
        ? all.firstWhere((t) => t.id == entry.id)
        : entry;
    final cats = ref.watch(categoryByIdProvider);
    final cat = cats[txn.categoryId];
    final color = context.semantic.byTypeKey(txn.type.key);

    String typeName() {
      switch (txn.type) {
        case TransactionType.income:
          return l10n.income;
        case TransactionType.expense:
          return l10n.spending;
        case TransactionType.loanGiven:
          return l10n.loanGiven;
        case TransactionType.loanTaken:
          return l10n.loanTaken;
      }
    }

    String dateLabel() {
      switch (txn.type) {
        case TransactionType.income:
          return l10n.incomeDate;
        case TransactionType.expense:
          return l10n.spendingDate;
        case TransactionType.loanGiven:
          return l10n.moneyGivenDate;
        case TransactionType.loanTaken:
          return l10n.moneyTakenDate;
      }
    }

    String recurrenceName() {
      switch (txn.recurrence) {
        case Recurrence.daily:
          return l10n.daily;
        case Recurrence.weekly:
          return l10n.weekly;
        case Recurrence.monthly:
          return l10n.monthly;
        case Recurrence.yearly:
          return l10n.yearly;
        case Recurrence.once:
          return l10n.oneTime;
      }
    }

    final subName = cat?.subCategories
        .where((s) => s.id == txn.subCategoryId)
        .map((s) => s.name)
        .join();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetails),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/dashboard/transaction', extra: txn),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: Icon(Icons.delete_outline, color: context.semantic.expense),
            onPressed: () => _confirmDelete(context, ref, txn, cat?.name),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                    offset: Offset(0, (1 - t) * 12), child: child),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Hero amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(typeName(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          Formatters.signedWhole(txn.type.sign * txn.amount),
                          style: TextStyle(
                              color: color,
                              fontSize: 34,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Row(
                    icon: cat != null
                        ? iconFromCode(cat.iconCode)
                        : Icons.category_outlined,
                    label: l10n.category,
                    value: cat?.name ?? '—',
                  ),
                  if (subName != null && subName.isNotEmpty)
                    _Row(
                      icon: Icons.subdirectory_arrow_right_rounded,
                      label: l10n.subcategory,
                      value: subName,
                    ),
                  _Row(
                    icon: Icons.calendar_today_outlined,
                    label: dateLabel(),
                    value: Formatters.dateDayTime(txn.date),
                  ),
                  if (txn.type.isLoan) ...[
                    if (txn.counterparty != null &&
                        txn.counterparty!.isNotEmpty)
                      _Row(
                        icon: Icons.person_outline,
                        label: l10n.personName,
                        value: txn.counterparty!,
                      ),
                    if (txn.interestPercent != null)
                      _Row(
                        icon: Icons.percent_rounded,
                        label: l10n.interest,
                        value: '${txn.interestPercent}%',
                      ),
                    if (txn.dueDate != null)
                      _Row(
                        icon: Icons.event_outlined,
                        label: l10n.returnCommitmentDate,
                        value: Formatters.fullDate(txn.dueDate!),
                      ),
                  ],
                  if (txn.isRecurring)
                    _Row(
                      icon: Icons.repeat_rounded,
                      label: l10n.recurring,
                      value:
                          '${recurrenceName()} · ${l10n.repeatStartsOn} ${Formatters.fullDate(txn.recurrenceStart ?? txn.date)}',
                    ),
                  if (txn.note.isNotEmpty)
                    _Row(
                      icon: Icons.sticky_note_2_outlined,
                      label: l10n.note,
                      value: txn.note,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                              '/dashboard/transaction',
                              extra: txn),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.edit),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: context.semantic.expense),
                          onPressed: () =>
                              _confirmDelete(context, ref, txn, cat?.name),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.delete),
                        ),
                      ),
                    ],
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

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, TxnEntry txn, String? catName) async {
  final l10n = AppLocalizations.of(context);
  final summary =
      '${Formatters.signedWhole(txn.type.sign * txn.amount)} · ${catName ?? ''} · ${Formatters.dayMonth(txn.date)}';
  final ok = await showAppConfirm(
    context,
    icon: Icons.delete_outline,
    title: l10n.delete,
    message: summary,
    confirmLabel: l10n.delete,
    danger: true,
  );
  if (!ok) return;
  await ref.read(transactionActionsProvider).delete(txn.id);
  if (context.mounted) context.pop();
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: context.semantic.muted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: context.semantic.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.semantic.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
