import 'package:flutter/material.dart';

import '../design/fin_icons.dart';
import '../design/motion.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';

/// Premium confirmation sheet: pulsing 3D icon, title, message, and a clear
/// primary / secondary action pair. Returns true when confirmed.
Future<bool> showAppConfirm(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String? confirmLabel,
  Color? accent,
  bool danger = false,
  Widget? extra,
}) async {
  final l10n = AppLocalizations.of(context);
  final color = accent ??
      (danger ? context.semantic.expense : Theme.of(context).colorScheme.primary);
  if (danger) AppHaptics.medium();
  final result = await showAppSheet<bool>(
    context,
    builder: (context, _) => ConfirmBody(
      icon: icon,
      color: color,
      title: title,
      message: message,
      extra: extra,
      cancelLabel: l10n.cancel,
      confirmLabel: confirmLabel ?? l10n.save,
      danger: danger,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    ),
  );
  return result ?? false;
}

/// Sub-category removal sheet with the "also delete entries" choice.
Future<({bool deleteEntries})?> showRemoveSubCategoryDialog(
  BuildContext context, {
  required String subName,
  required int entryCount,
}) {
  final l10n = AppLocalizations.of(context);
  var deleteEntries = true;
  return showAppSheet<({bool deleteEntries})>(
    context,
    builder: (context, setSheet) => ConfirmBody(
      icon: Icons.delete_sweep_rounded,
      color: context.semantic.expense,
      title: l10n.removeSubcategory,
      message: '“$subName”',
      danger: true,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.remove,
      extra: _CheckRow(
        value: deleteEntries,
        label: l10n.deleteSubLedgers,
        caption: entryCount > 0 ? '$entryCount' : null,
        onChanged: (v) => setSheet(() => deleteEntries = v),
      ),
      onConfirm: () =>
          Navigator.pop(context, (deleteEntries: deleteEntries)),
      onCancel: () => Navigator.pop(context),
    ),
  );
}

/// The body used by confirmation sheets. Public so feature sheets with
/// extra inputs (e.g. delete account + password) share the same look.
class ConfirmBody extends StatelessWidget {
  const ConfirmBody({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.danger = false,
    this.extra,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool danger;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Entrance(
          child: _PulseHalo(
            color: color,
            child: Icon3D(icon: icon, color: color, size: 68),
          ),
        ),
        const SizedBox(height: 18),
        Entrance(
          index: 1,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Entrance(
          index: 2,
          child: Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.semantic.muted, height: 1.45),
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: 14),
          Entrance(index: 3, child: extra!),
        ],
        const SizedBox(height: 22),
        Entrance(
          index: 3,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: cancelLabel,
                  variant: AppButtonVariant.secondary,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  variant: danger
                      ? AppButtonVariant.danger
                      : AppButtonVariant.primary,
                  color: danger ? null : color,
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulseHalo extends StatefulWidget {
  const _PulseHalo({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Container(
              width: 70 + 50 * _c.value,
              height: 70 + 50 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.18 * (1 - _c.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.value,
    required this.label,
    required this.onChanged,
    this.caption,
  });

  final bool value;
  final String label;
  final String? caption;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.semantic.expense;
    return Pressable(
      onTap: () {
        AppHaptics.select();
        onChanged(!value);
      },
      haptic: false,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? c.withValues(alpha: 0.08)
              : context.surfaces.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: value ? c.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? c : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value ? c : context.semantic.muted,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white,)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (caption != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
