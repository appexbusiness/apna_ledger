import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/category.dart';

/// Opens the create/edit category sheet and returns the built [Category]
/// (NOT yet saved — the caller persists it via categoryActionsProvider).
Future<Category?> showCategoryEditor(
  BuildContext context, {
  Category? existing,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CategoryEditorSheet(existing: existing),
    ),
  );
}

class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({super.key, this.existing});
  final Category? existing;

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  static const _icons = <IconData>[
    Icons.storefront_outlined,
    Icons.family_restroom_outlined,
    Icons.payments_outlined,
    Icons.account_balance_outlined,
    Icons.receipt_long_outlined,
    Icons.flight_takeoff_outlined,
    Icons.restaurant_outlined,
    Icons.trending_up_outlined,
    Icons.shopping_bag_outlined,
    Icons.directions_car_outlined,
    Icons.school_outlined,
    Icons.medical_services_outlined,
    Icons.sports_esports_outlined,
    Icons.pets_outlined,
    Icons.home_outlined,
    Icons.card_giftcard_outlined,
  ];

  late TextEditingController _name;
  late int _iconCode;
  late int _colorIndex;
  final List<_SubField> _subs = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _iconCode = widget.existing?.iconCode ?? _icons.first.codePoint;
    _colorIndex = widget.existing?.colorIndex ?? 0;
    for (final s in widget.existing?.subCategories ?? const []) {
      _subs.add(_SubField(s.id, TextEditingController(text: s.name)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final s in _subs) {
      s.controller.dispose();
    }
    super.dispose();
  }

  void _addSubField() =>
      setState(() => _subs.add(_SubField(const Uuid().v4(), TextEditingController())));

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final seen = <String>{};
    final subs = <SubCategory>[];
    for (final f in _subs) {
      final n = f.controller.text.trim();
      if (n.isEmpty || !seen.add(n.toLowerCase())) continue;
      subs.add(SubCategory(id: f.id, name: n));
    }
    final base = widget.existing;
    final category = base == null
        ? Category(
            id: const Uuid().v4(),
            name: name,
            iconCode: _iconCode,
            colorIndex: _colorIndex,
            subCategories: subs,
          )
        : base.copyWith(
            name: name,
            iconCode: _iconCode,
            colorIndex: _colorIndex,
            subCategories: subs);
    Navigator.pop(context, category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing == null ? l10n.addCategory : l10n.category,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _name,
            label: l10n.categoryName,
            hint: l10n.categoryName,
          ),
          const SizedBox(height: 20),
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final icon in _icons)
                _IconChoice(
                  icon: icon,
                  selected: _iconCode == icon.codePoint,
                  color: AppColors.chartFor(_colorIndex),
                  onTap: () => setState(() => _iconCode = icon.codePoint),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Colour', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < AppColors.chart.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: AppColors.chartFor(i),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _colorIndex == i
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('${l10n.addSubcategory} (${l10n.optional})',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < _subs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _subs[i].controller,
                      hint: l10n.subcategory,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: context.semantic.muted),
                    onPressed: () => setState(() {
                      final f = _subs.removeAt(i);
                      f.controller.dispose();
                    }),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addSubField,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addSubcategory),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.save,
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : context.semantic.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Icon(icon, color: selected ? color : context.semantic.muted),
      ),
    );
  }
}

class _SubField {
  _SubField(this.id, this.controller);
  final String id;
  final TextEditingController controller;
}
