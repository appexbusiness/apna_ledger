import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/icon_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/name_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../transactions/presentation/new_txn_args.dart';

/// Horizontal strip of 3D category tiles. Tapping one opens a sheet of its
/// sub-categories, each a one-tap "add entry here", plus "add sub-category".
class QuickCategories extends ConsumerWidget {
  const QuickCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesStreamProvider).value ?? const [];
    if (cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = cats[i];
          final color = AppColors.chartFor(c.colorIndex);
          return Entrance(
            index: i,
            child: Pressable(
              onTap: () => _openCategorySheet(context, ref, c),
              pressedScale: 0.92,
              child: Container(
                width: 88,
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [context.surfaces.cardHi, context.surfaces.card],
                  ),
                  boxShadow: context.surfaces.elevation(0.5),
                ),
                child: Column(
                  children: [
                    Icon3D(
                      icon: iconFromCode(c.iconCode),
                      color: color,
                      size: 40,
                    ),
                    const Spacer(),
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _openCategorySheet(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l10n = AppLocalizations.of(context);
  final color = AppColors.chartFor(category.colorIndex);
  final router = GoRouter.of(context);

  void add(String? subId) {
    Navigator.of(context, rootNavigator: true).pop();
    router.push(
      '/dashboard/transaction',
      extra: NewTxnArgs(categoryId: category.id, subCategoryId: subId),
    );
  }

  await showAppSheet<void>(
    context,
    title: category.name,
    subtitle: l10n.tapToAdd,
    accent: color,
    glyph: FinGlyph.categories,
    builder: (sheetContext, _) => Consumer(
      builder: (context, ref, _) {
        // Stay live so a newly added sub-category appears immediately.
        final live = (ref.watch(categoriesStreamProvider).value ?? const [])
                .where((c) => c.id == category.id)
                .firstOrNull ??
            category;
        return Column(
          children: [
            SheetOption(
              title: '${l10n.addTransaction} · ${live.name}',
              icon: iconFromCode(live.iconCode),
              color: color,
              onTap: () => add(null),
            ),
            for (var i = 0; i < live.subCategories.length; i++)
              Entrance(
                index: i,
                offset: 10,
                child: SheetOption(
                  title: live.subCategories[i].name,
                  icon: Icons.subdirectory_arrow_right_rounded,
                  color: color,
                  trailing: Icon(Icons.add_circle_rounded, color: color),
                  onTap: () => add(live.subCategories[i].id),
                ),
              ),
            SheetOption(
              title: l10n.addSubcategory,
              icon: Icons.create_new_folder_rounded,
              color: context.semantic.muted,
              onTap: () => _addSubCategory(context, ref, live),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _addSubCategory(
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
    accent: AppColors.chartFor(category.colorIndex),
  );
  if (name == null || name.isEmpty) return;
  // Guard against accidental duplicates within the same category.
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
