import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design/design.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
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
  final l10n = AppLocalizations.of(context);
  return showAppSheet<Category>(
    context,
    title: existing == null ? l10n.addCategory : l10n.edit,
    glyph: FinGlyph.categories,
    builder: (context, _) => CategoryEditorSheet(existing: existing),
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
  int _nameShake = 0;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '')
      ..addListener(() => setState(() {}));
    _iconCode = widget.existing?.iconCode ?? _icons.first.codePoint;
    _colorIndex = widget.existing?.colorIndex ?? 0;
    for (final s in widget.existing?.subCategories ?? const <SubCategory>[]) {
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

  void _addSubField() => setState(
        () => _subs.add(_SubField(const Uuid().v4(), TextEditingController())),
      );

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameShake++);
      return;
    }
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
            subCategories: subs,
          );
    Navigator.pop(context, category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AppColors.chartFor(_colorIndex);
    final icon = _icons.firstWhere(
      (i) => i.codePoint == _iconCode,
      orElse: () => _icons.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live preview.
        Center(
          child: AnimatedContainer(
            duration: AppMotion.medium,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              children: [
                PopOnChange(
                  trigger: '$_iconCode-$_colorIndex',
                  child: Floating(
                    amplitude: 4,
                    child: Icon3D(icon: icon, color: color, size: 72),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _name.text.trim().isEmpty
                      ? l10n.categoryName
                      : _name.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: _name.text.trim().isEmpty
                        ? context.semantic.muted
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Shake(
          trigger: _nameShake,
          child: AppTextField(
            controller: _name,
            label: l10n.categoryName,
            icon: Icons.drive_file_rename_outline_rounded,
            accent: color,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: 20),
        const GroupLabel('Icon', padding: EdgeInsets.fromLTRB(4, 0, 4, 10)),
        LayoutBuilder(
          builder: (context, c) {
            const cols = 8;
            final size = ((c.maxWidth - 7 * 8) / cols).clamp(36.0, 56.0);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in _icons)
                  _IconChoice(
                    icon: i,
                    size: size,
                    selected: _iconCode == i.codePoint,
                    color: color,
                    onTap: () => setState(() => _iconCode = i.codePoint),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const GroupLabel('Colour', padding: EdgeInsets.fromLTRB(4, 0, 4, 10)),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < AppColors.chart.length; i++)
              _ColorBall(
                color: AppColors.chartFor(i),
                selected: _colorIndex == i,
                onTap: () => setState(() => _colorIndex = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GroupLabel(
          '${l10n.addSubcategory} (${l10n.optional})',
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        ),
        for (var i = 0; i < _subs.length; i++)
          Entrance(
            key: ValueKey(_subs[i].id),
            offset: 10,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _subs[i].controller,
                      label: l10n.subcategory,
                      icon: Icons.subdirectory_arrow_right_rounded,
                      accent: color,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconOrb(
                    icon: Icons.close_rounded,
                    size: 38,
                    color: context.semantic.muted,
                    onTap: () => setState(() {
                      final f = _subs.removeAt(i);
                      f.controller.dispose();
                    }),
                  ),
                ],
              ),
            ),
          ),
        AppButton(
          label: l10n.addSubcategory,
          icon: Icons.add_rounded,
          variant: AppButtonVariant.secondary,
          height: 50,
          onPressed: _addSubField,
        ),
        const SizedBox(height: 22),
        AppButton(
          label: l10n.save,
          icon: Icons.check_rounded,
          color: color,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.size,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      haptic: false,
      pressedScale: 0.88,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: AppMotion.medium,
        curve: AppMotion.bouncy,
        child: Icon3D(
          icon: icon,
          color: selected ? color : context.semantic.muted,
          size: size,
          style: selected ? Icon3DStyle.solid : Icon3DStyle.soft,
        ),
      ),
    );
  }
}

class _ColorBall extends StatelessWidget {
  const _ColorBall({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      haptic: false,
      pressedScale: 0.85,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [AppColors.lighten(color, 0.2), color, AppColors.darken(color, 0.12)],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected ? AppSurfaces.glow(color) : null,
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: selected
              ? const Icon(Icons.check_rounded,
                  key: ValueKey('on'), color: Colors.white, size: 20,)
              : const SizedBox.shrink(key: ValueKey('off')),
        ),
      ),
    );
  }
}

class _SubField {
  _SubField(this.id, this.controller);
  final String id;
  final TextEditingController controller;
}
