import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/widgets/animated_money.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/name_sheet.dart';
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
    final count = catsAsync.value?.length ?? 0;

    return Scaffold(
      body: AmbientBackground(
        tint: const Color(0xFF06B6D4),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ScreenHeader(
                      title: l10n.categories,
                      subtitle: '$count · ${l10n.manageCategories}',
                      actions: [
                        IconOrb(
                          icon: Icons.add_rounded,
                          tooltip: l10n.addCategory,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => _createCategory(context, ref),
                        ),
                      ],
                    ),
                  ),
                  ...catsAsync.when(
                    loading: () => [
                      const SliverPadding(
                        padding: EdgeInsets.all(20),
                        sliver: SliverToBoxAdapter(child: LedgerSkeleton()),
                      ),
                    ],
                    error: (e, _) => [
                      SliverToBoxAdapter(
                        child: ErrorState(
                          onRetry: () =>
                              ref.invalidate(categoriesStreamProvider),
                        ),
                      ),
                    ],
                    data: (cats) => [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                        sliver: SliverLayoutBuilder(
                          builder: (context, c) {
                            final cols = c.crossAxisExtent > 560 ? 3 : 2;
                            return SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisExtent: 176,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                              itemCount: cats.length + 1,
                              itemBuilder: (context, i) => Entrance(
                                index: i,
                                child: i == cats.length
                                    ? _NewCategoryCard(
                                        onTap: () =>
                                            _createCategory(context, ref),
                                      )
                                    : _CategoryCard(category: cats[i]),
                              ),
                            );
                          },
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

void _openHistory(
  GoRouter router,
  WidgetRef ref, {
  required String categoryId,
  String? subCategoryId,
}) {
  ref.read(txnFilterProvider.notifier).state = TxnFilter(
    categoryId: categoryId,
    subCategoryId: subCategoryId,
  );
  router.go('/dashboard/transactions');
}

Future<void> _createCategory(
  BuildContext context,
  WidgetRef ref, {
  Category? existing,
}) async {
  final toast = Toaster.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await showCategoryEditor(context, existing: existing);
  if (result == null) return;
  final cats = ref.read(categoriesStreamProvider).value ?? const [];
  final duplicate = cats.any(
    (c) => c.id != result.id && c.name.toLowerCase() == result.name.toLowerCase(),
  );
  if (duplicate) {
    toast.error(l10n.duplicateName);
    return;
  }
  await ref.read(categoryActionsProvider).save(result);
  toast.success(l10n.savedToast);
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.chartFor(category.colorIndex);
    final semantic = context.semantic;
    final totals = ref.watch(categoryTotalsProvider)[category.id] ??
        (income: 0.0, expense: 0.0);
    final count = ref.watch(categoryCountProvider)[category.id] ?? 0;
    final flow = totals.income + totals.expense;

    return Surface3D(
      onTap: () => showCategorySheet(context, category.id),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon3D(icon: iconFromCode(category.iconCode), color: color, size: 46),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 12, color: color),
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          if (category.subCategories.isNotEmpty)
            Text(
              category.subCategories.map((s) => s.name).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: semantic.muted, fontSize: 11.5),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.arrow_drop_up_rounded, color: semantic.income, size: 18),
              Flexible(
                child: AnimatedMoney(
                  totals.income,
                  style: TextStyle(
                    color: semantic.income,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_drop_down_rounded,
                  color: semantic.expense, size: 18,),
              Flexible(
                child: AnimatedMoney(
                  totals.expense,
                  style: TextStyle(
                    color: semantic.expense,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SplitBar(
            left: flow <= 0 ? 1 : totals.income,
            right: flow <= 0 ? 1 : totals.expense,
            leftColor: flow <= 0 ? semantic.border : semantic.income,
            rightColor: flow <= 0 ? semantic.border : semantic.expense,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _NewCategoryCard extends StatelessWidget {
  const _NewCategoryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme.primary;
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.withValues(alpha: 0.45), width: 1.6),
          color: c.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Floating(
              amplitude: 4,
              child: Icon3D(icon: Icons.add_rounded, color: c, size: 50),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.addCategory,
              style: TextStyle(color: c, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category detail sheet: totals, actions and sub-categories. Stays live
/// while open so edits show immediately.
Future<void> showCategorySheet(BuildContext context, String categoryId) {
  return showAppSheet<void>(
    context,
    builder: (context, _) => _CategorySheetBody(categoryId: categoryId),
  );
}

class _CategorySheetBody extends ConsumerWidget {
  const _CategorySheetBody({required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final category = ref.watch(categoryByIdProvider)[categoryId];
    if (category == null) return const SizedBox(height: 120);
    final color = AppColors.chartFor(category.colorIndex);
    final semantic = context.semantic;
    final totals = ref.watch(categoryTotalsProvider)[category.id] ??
        (income: 0.0, expense: 0.0);
    final subTotals = ref.watch(subCategoryTotalsProvider);
    final router = GoRouter.of(context);

    void closeThen(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    final actions = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.add_circle_rounded,
        l10n.addTransaction,
        color,
        () => closeThen(
              () => router.push(
                '/dashboard/transaction',
                extra: NewTxnArgs(categoryId: category.id),
              ),
            ),
      ),
      (
        Icons.create_new_folder_rounded,
        l10n.addSubcategory,
        AppColors.primary,
        () => _addSub(context, ref, category),
      ),
      (
        Icons.history_rounded,
        l10n.ledgerHistory,
        AppColors.info,
        () => closeThen(
              () => _openHistory(router, ref, categoryId: category.id),
            ),
      ),
      (
        Icons.download_rounded,
        l10n.download,
        AppColors.income,
        () => _exportCategory(context, ref, category),
      ),
      if (!category.isDefault)
        (
          Icons.edit_rounded,
          l10n.edit,
          AppColors.loanGiven,
          () => _createCategory(context, ref, existing: category),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header.
        Row(
          children: [
            Floating(
              amplitude: 3,
              child: Icon3D(
                icon: iconFromCode(category.iconCode),
                color: color,
                size: 58,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name,
                      style: Theme.of(context).textTheme.titleLarge,),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Total(
                        label: l10n.income,
                        value: totals.income,
                        color: semantic.income,
                      ),
                      const SizedBox(width: 16),
                      _Total(
                        label: l10n.spending,
                        value: totals.expense,
                        color: semantic.expense,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Actions.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (i, a) in actions.indexed)
              Entrance(
                index: i,
                offset: 10,
                child: Pressable(
                  onTap: a.$4,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: a.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: a.$3.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon3D(icon: a.$1, color: a.$3, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          a.$2,
                          style: TextStyle(
                            color: a.$3,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (category.subCategories.isNotEmpty) ...[
          const SizedBox(height: 22),
          GroupLabel(l10n.subcategory,
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),),
          for (final (i, s) in category.subCategories.indexed)
            Entrance(
              index: i,
              offset: 10,
              child: _SubRow(
                sub: s,
                color: color,
                totals: subTotals[s.id] ?? (income: 0.0, expense: 0.0),
                onTap: () => closeThen(
                  () => _openHistory(
                    router,
                    ref,
                    categoryId: category.id,
                    subCategoryId: s.id,
                  ),
                ),
                onAdd: () => closeThen(
                  () => router.push(
                    '/dashboard/transaction',
                    extra: NewTxnArgs(
                      categoryId: category.id,
                      subCategoryId: s.id,
                    ),
                  ),
                ),
                onDelete: () => _confirmRemoveSub(context, ref, category, s),
              ),
            ),
        ],
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.semantic.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CountUp(
              value: value,
              format: Formatters.moneySmart,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _addSub(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l10n = AppLocalizations.of(context);
  final toast = Toaster.of(context);
  final name = await showNameSheet(
    context,
    title: l10n.addSubcategory,
    label: l10n.subcategoryName,
    hint: 'Add your ${category.name} name',
    accent: AppColors.chartFor(category.colorIndex),
  );
  if (name == null || name.isEmpty) return;
  // No duplicate sub-category names (case-insensitive).
  final exists = category.subCategories
      .any((s) => s.name.toLowerCase() == name.toLowerCase());
  if (exists) {
    toast.error(l10n.duplicateName);
    return;
  }
  final updated = category.copyWith(
    subCategories: [
      ...category.subCategories,
      SubCategory(id: const Uuid().v4(), name: name),
    ],
  );
  await ref.read(categoryActionsProvider).save(updated);
  toast.success(l10n.savedToast);
}

Future<void> _confirmRemoveSub(
  BuildContext context,
  WidgetRef ref,
  Category category,
  SubCategory sub,
) async {
  final l10n = AppLocalizations.of(context);
  final toast = Toaster.of(context);
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
    subCategories: category.subCategories.where((s) => s.id != sub.id).toList(),
  );
  await ref.read(categoryActionsProvider).save(updated);

  toast.success(choice.deleteEntries ? l10n.subRemoved : l10n.subEntriesKept);
}

Future<void> _exportCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
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

class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.sub,
    required this.color,
    required this.totals,
    required this.onTap,
    required this.onAdd,
    required this.onDelete,
  });

  final SubCategory sub;
  final Color color;
  final ({double income, double expense}) totals;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            color: context.surfaces.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: semantic.border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: AnimatedMoney(
                            totals.income,
                            style: TextStyle(
                              color: semantic.income,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: AnimatedMoney(
                            totals.expense,
                            style: TextStyle(
                              color: semantic.expense,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.addTransaction,
                icon: Icon(Icons.add_circle_rounded, color: color),
                onPressed: onAdd,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.remove,
                icon: Icon(Icons.close_rounded, size: 18, color: semantic.muted),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
