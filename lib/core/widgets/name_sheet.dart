import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/fin_icons.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Asks for a single name (category, sub-category…) in a sheet.
/// Returns the trimmed text, or null when dismissed.
Future<String?> showNameSheet(
  BuildContext context, {
  required String title,
  String? label,
  String hint = '',
  String initial = '',
  FinGlyph glyph = FinGlyph.categories,
  Color? accent,
}) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  void submit(BuildContext ctx) =>
      Navigator.pop(ctx, controller.text.trim());

  return showAppSheet<String>(
    context,
    title: title,
    glyph: glyph,
    accent: accent,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: controller,
          label: label ?? title,
          hint: hint,
          autofocus: true,
          icon: Icons.drive_file_rename_outline_rounded,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit(context),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.save,
          icon: Icons.check_rounded,
          color: accent,
          onPressed: () => submit(context),
        ),
      ],
    ),
  ).whenComplete(() {
    // Let the sheet finish its exit animation before disposing.
    Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  });
}
