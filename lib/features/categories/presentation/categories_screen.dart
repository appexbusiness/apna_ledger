import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/widgets/animated_money.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/ledger_export.dart';
import '../../transactions/presentation/new_txn_args.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../domain/category.dart';
import 'category_editor.dart';
import 'category_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catsAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          TextButton.icon(
            onPressed: () => _createCategory(context, ref),
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.addCategory),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: catsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.somethingWrong)),
          data: (cats) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  for (final c in cats) _CategoryCard(category: c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openHistory(BuildContext context, WidgetRef ref,
    {required String categoryId, String? subCategoryId}) {
  ref.read(txnFilterProvider.notifier).state = TxnFilter(
    categoryId: categoryId,
    subCategoryId: subCategoryId,
  );
  context.go('/dashboard/transactions');
}

Future<void> _createCategory(BuildContext context, WidgetRef ref,
    {Category? existing}) async {
  final result = await showCategoryEditor(context, existing: existing);
  if (result == null) return;
  final cats = ref.read(categoriesStreamProvider).value ?? const [];
  final duplicate = cats.any((c) =>
      c.id != result.id &&
      c.name.toLowerCase() == result.name.toLowerCase());
  if (duplicate) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).duplicateName)));
    }
    return;
  }
  await ref.read(categoryActionsProvider).save(result);
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = AppColors.chartFor(category.colorIndex);
    final semantic = context.semantic;
    final totals = ref.watch(categoryTotalsProvider)[category.id] ??
        (income: 0.0, expense: 0.0);
    final subTotals = ref.watch(subCategoryTotalsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconFromCode(category.iconCode), color: color),
          ),
          title: Text(category.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Text('▲ ', style: TextStyle(color: semantic.income, fontSize: 12)),
              Flexible(
                child: AnimatedMoney(totals.income,
                    style: TextStyle(color: semantic.income, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text('▼ ', style: TextStyle(color: semantic.expense, fontSize: 12)),
              Flexible(
                child: AnimatedMoney(totals.expense,
                    style: TextStyle(color: semantic.expense, fontSize: 12)),
              ),
            ],
          ),
          trailing: const Icon(Icons.expand_more_rounded),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final s in category.subCategories)
              _SubRow(
                sub: s,
                totals: subTotals[s.id] ?? (income: 0.0, expense: 0.0),
                onTap: () => _openHistory(context, ref,
                    categoryId: category.id, subCategoryId: s.id),
                onAdd: () => context.push('/dashboard/transaction',
                    extra: NewTxnArgs(
                        categoryId: category.id, subCategoryId: s.id)),
                onDelete: () => _confirmRemoveSub(context, ref, s),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(l10n.addTransaction),
                  onPressed: () => context.push('/dashboard/transaction',
                      extra: NewTxnArgs(categoryId: category.id)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addSubcategory),
                  onPressed: () => _addSub(context, ref),
                ),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(l10n.ledgerHistory),
                  onPressed: () =>
                      _openHistory(context, ref, categoryId: category.id),
                ),
                ActionChip(
                  avatar: const Icon(Icons.download_outlined, size: 18),
                  label: Text(l10n.download),
                  onPressed: () => _exportCategory(context, ref),
                ),
                if (!category.isDefault)
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: () =>
                        _createCategory(context, ref, existing: category),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSub(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final hint = 'Add your ${category.name} name';
    final name = await _promptName(
      context,
      l10n.addSubcategory,
      hint: hint,
    );
    if (name == null || name.isEmpty) return;
    // No duplicate sub-category names (case-insensitive).
    final exists = category.subCategories
        .any((s) => s.name.toLowerCase() == name.toLowerCase());
    if (exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.duplicateName)));
      }
      return;
    }
    final updated = category.copyWith(
      subCategories: [
        ...category.subCategories,
        SubCategory(id: const Uuid().v4(), name: name),
      ],
    );
    await ref.read(categoryActionsProvider).save(updated);
  }

  Future<void> _confirmRemoveSub(
      BuildContext context, WidgetRef ref, SubCategory sub) async {
    final l10n = AppLocalizations.of(context);
    final all = ref.read(transactionsStreamProvider).value ?? const [];
    final count = all
        .where((t) => t.categoryId == category.id && t.subCategoryId == sub.id)
        .length;

    final choice = await showRemoveSubCategoryDialog(
      context,
      subName: sub.name,
      entryCount: count,
    );
    if (choice == null) return;

    // 1) Handle the sub-category's entries (delete or move to parent).
    await ref.read(transactionActionsProvider).handleSubCategoryRemoval(
          categoryId: category.id,
          subId: sub.id,
          deleteEntries: choice.deleteEntries,
        );
    // 2) Remove the sub-category label itself.
    final updated = category.copyWith(
      subCategories:
          category.subCategories.where((s) => s.id != sub.id).toList(),
    );
    await ref.read(categoryActionsProvider).save(updated);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            choice.deleteEntries ? l10n.subRemoved : l10n.subEntriesKept),
      ));
    }
  }

  Future<void> _exportCategory(BuildContext context, WidgetRef ref) async {
    final all = ref.read(transactionsStreamProvider).value ?? const [];
    final rows = all.where((t) => t.categoryId == category.id).toList();
    await runLedgerDownload(
      context,
      ref,
      source: rows,
      fileBase: 'apna-ledger-${category.name}',
      title: category.name,
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.sub,
    required this.totals,
    required this.onTap,
    required this.onAdd,
    required this.onDelete,
  });
  final SubCategory sub;
  final ({double income, double expense}) totals;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.subdirectory_arrow_right_rounded,
                size: 18, color: semantic.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(sub.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            AnimatedMoney(totals.income,
                style: TextStyle(color: semantic.income, fontSize: 12)),
            const SizedBox(width: 8),
            AnimatedMoney(totals.expense,
                style: TextStyle(color: semantic.expense, fontSize: 12)),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context).addTransaction,
              icon: Icon(Icons.add_circle_outline,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              onPressed: onAdd,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 16, color: semantic.muted),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _promptName(BuildContext context, String title,
    {String hint = '', String initial = ''}) {
  final controller = TextEditingController(text: initial);
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: AppTextField(
        controller: controller,
        hint: hint.isEmpty ? l10n.categoryName : hint,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}
