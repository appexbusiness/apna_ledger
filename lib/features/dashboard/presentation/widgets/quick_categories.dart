import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../transactions/presentation/new_txn_args.dart';

/// Horizontal category cards. Tap a card's arrow to reveal its sub-categories,
/// each with a + to add a transaction straight into it.
class QuickCategories extends ConsumerStatefulWidget {
  const QuickCategories({super.key});

  @override
  ConsumerState<QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends ConsumerState<QuickCategories> {
  String? _expandedId;

  void _add(String categoryId, [String? subId]) {
    context.push('/dashboard/transaction',
        extra: NewTxnArgs(categoryId: categoryId, subCategoryId: subId));
  }

  Future<void> _addSubCategory(Category category) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addSubcategory),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.subcategoryName),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    // Guard against accidental duplicates within the same category.
    final exists = category.subCategories
        .any((s) => s.name.toLowerCase() == name.toLowerCase());
    if (exists) return;
    final updated = category.copyWith(subCategories: [
      ...category.subCategories,
      SubCategory(id: const Uuid().v4(), name: name),
    ]);
    await ref.read(categoryActionsProvider).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cats = ref.watch(categoriesStreamProvider).value ?? const [];
    if (cats.isEmpty) return const SizedBox.shrink();
    Category? expanded;
    for (final c in cats) {
      if (c.id == _expandedId) expanded = c;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = cats[i];
              final color = AppColors.chartFor(c.colorIndex);
              final open = c.id == _expandedId;
              return Material(
                color: color.withValues(alpha: open ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () =>
                      setState(() => _expandedId = open ? null : c.id),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(iconFromCode(c.iconCode), size: 18, color: color),
                        const SizedBox(width: 6),
                        Text(c.name,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: expanded == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 16),
                                label: Text(expanded.name),
                                onPressed: () => _add(expanded!.id),
                              ),
                              for (final s in expanded.subCategories)
                                ActionChip(
                                  avatar:
                                      const Icon(Icons.add, size: 16),
                                  label: Text(s.name),
                                  onPressed: () => _add(expanded!.id, s.id),
                                ),
                              ActionChip(
                                avatar: Icon(Icons.add_circle_outline_rounded,
                                    size: 16, color: context.semantic.muted),
                                label: Text(l10n.addSubcategory),
                                onPressed: () => _addSubCategory(expanded!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
