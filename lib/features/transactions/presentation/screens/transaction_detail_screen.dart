import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_providers.dart';
import '../txn_ui.dart';

/// Opens an entry's details as a bottom sheet (the default for ledger taps).
Future<void> showTransactionDetailSheet(BuildContext context, TxnEntry txn) {
  return showAppSheet<void>(
    context,
    builder: (context, _) =>
        TransactionDetailBody(entry: txn, inSheet: true),
  );
}

/// Full-page variant, kept for the `/dashboard/transaction/view` route.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.entry});
  final TxnEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ScreenHeader(
                    title: l10n.transactionDetails,
                    onBack: () => context.pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TransactionDetailBody(entry: entry),
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

/// Read-only, receipt-style view of one entry with Edit / Delete actions.
class TransactionDetailBody extends ConsumerWidget {
  const TransactionDetailBody({
    super.key,
    required this.entry,
    this.inSheet = false,
  });

  final TxnEntry entry;
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(transactionsStreamProvider).value ?? const [];
    // Stay fresh after edits; fall back to the passed entry.
    final txn = all.where((t) => t.id == entry.id).firstOrNull ?? entry;
    final cats = ref.watch(categoryByIdProvider);
    final cat = cats[txn.categoryId];
    final color = context.semantic.byTypeKey(txn.type.key);
    final subName = cat?.subCategories
        .where((s) => s.id == txn.subCategoryId)
        .map((s) => s.name)
        .join();

    final rows = <_DetailRow>[
      _DetailRow(
        icon: cat != null ? iconFromCode(cat.iconCode) : Icons.category_rounded,
        color: AppColors.chartFor(cat?.colorIndex ?? 0),
        label: l10n.category,
        value: cat?.name ?? '—',
      ),
      if (subName != null && subName.isNotEmpty)
        _DetailRow(
          icon: Icons.subdirectory_arrow_right_rounded,
          color: AppColors.chartFor(cat?.colorIndex ?? 0),
          label: l10n.subcategory,
          value: subName,
        ),
      _DetailRow(
        icon: Icons.calendar_month_rounded,
        color: AppColors.info,
        label: txn.type.dateLabel(l10n),
        value: Formatters.dateDayTime(txn.date),
      ),
      if (txn.type.isLoan) ...[
        if (txn.counterparty != null && txn.counterparty!.isNotEmpty)
          _DetailRow(
            icon: Icons.person_rounded,
            color: color,
            label: l10n.personName,
            value: txn.counterparty!,
          ),
        if (txn.interestPercent != null)
          _DetailRow(
            icon: Icons.percent_rounded,
            color: const Color(0xFFF97316),
            label: l10n.interest,
            value: '${txn.interestPercent}%',
          ),
        if (txn.dueDate != null)
          _DetailRow(
            icon: Icons.event_available_rounded,
            color: AppColors.loanTaken,
            label: l10n.returnCommitmentDate,
            value: Formatters.fullDate(txn.dueDate!),
          ),
      ],
      if (txn.isRecurring)
        _DetailRow(
          icon: Icons.event_repeat_rounded,
          color: AppColors.loanTaken,
          label: l10n.recurring,
          value:
              '${txn.recurrence.label(l10n)} · ${l10n.repeatStartsOn} ${Formatters.fullDate(txn.recurrenceStart ?? txn.date)}',
        ),
      if (txn.note.isNotEmpty)
        _DetailRow(
          icon: Icons.sticky_note_2_rounded,
          color: const Color(0xFFE9A20F),
          label: l10n.note,
          value: txn.note,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero amount.
        Entrance(
          child: Surface3D(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                Floating(
                  amplitude: 4,
                  child: Icon3D(glyph: txn.type.glyph, size: 64),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    txn.type.label(l10n),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CountUp(
                    value: txn.type.sign * txn.amount,
                    format: Formatters.signedWhole,
                    style: AppTypography.money(size: 38, color: color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.fullDate(txn.date),
                  style: TextStyle(
                    color: context.semantic.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Receipt rows.
        Entrance(
          index: 1,
          child: Surface3D(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const _DashedDivider(),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Entrance(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.edit,
                  icon: Icons.edit_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    final router = GoRouter.of(context);
                    if (inSheet) Navigator.of(context).pop();
                    router.push('/dashboard/transaction', extra: txn);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.delete,
                  icon: Icons.delete_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    final deleted = await confirmDeleteTransaction(
                        context, ref, txn, cat?.name,);
                    if (deleted && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Confirms, deletes, and toasts. Returns true when the entry was deleted.
Future<bool> confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  TxnEntry txn,
  String? catName,
) async {
  final l10n = AppLocalizations.of(context);
  final toast = Toaster.of(context);
  final summary =
      '${Formatters.signedWhole(txn.type.sign * txn.amount)} · ${catName ?? ''} · ${Formatters.dayMonth(txn.date)}';
  final ok = await showAppConfirm(
    context,
    icon: Icons.delete_rounded,
    title: l10n.delete,
    message: summary,
    confirmLabel: l10n.delete,
    danger: true,
  );
  if (!ok) return false;
  try {
    await ref.read(transactionActionsProvider).delete(txn.id);
    toast.success(l10n.deletedToast);
    return true;
  } catch (_) {
    toast.error(l10n.somethingWrong);
    return false;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon3D(icon: icon, color: color, size: 38, style: Icon3DStyle.soft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.semantic.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.semantic.border;
    return LayoutBuilder(
      builder: (context, box) {
        final n = (box.maxWidth / 9).floor();
        return Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Container(
                  height: 1.2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: c,
                ),
              ),
          ],
        );
      },
    );
  }
}
