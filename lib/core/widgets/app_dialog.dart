import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// A styled confirmation shown as an animated bottom sheet (icon header,
/// message, actions). Returns true when confirmed.
Future<bool> showAppConfirm(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String? confirmLabel,
  Color? accent,
  bool danger = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final color = accent ??
      (danger
          ? context.semantic.expense
          : Theme.of(context).colorScheme.primary);
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SheetBody(
      icon: icon,
      color: color,
      title: title,
      message: message,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: color)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n.save),
        ),
      ],
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
  return showModalBottomSheet<({bool deleteEntries})>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      var deleteEntries = true;
      return StatefulBuilder(
        builder: (context, setSheet) => _SheetBody(
          icon: Icons.delete_sweep_outlined,
          color: context.semantic.expense,
          title: l10n.removeSubcategory,
          message: '“$subName”',
          extra: CheckboxListTile(
            value: deleteEntries,
            onChanged: (v) => setSheet(() => deleteEntries = v ?? true),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.deleteSubLedgers,
                style: const TextStyle(fontSize: 13.5)),
            subtitle: entryCount > 0
                ? Text('$entryCount',
                    style: TextStyle(
                        color: context.semantic.muted, fontSize: 12))
                : null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: context.semantic.expense),
              onPressed: () =>
                  Navigator.pop(context, (deleteEntries: deleteEntries)),
              child: Text(l10n.remove),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actions,
    this.extra,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? extra;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 4, 24, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.semantic.muted)),
          if (extra != null) extra!,
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}
