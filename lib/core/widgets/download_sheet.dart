import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/fin_icons.dart';
import 'app_bottom_sheet.dart';

/// Asks the user which format to download. Returns 'csv', 'pdf', or null.
Future<String?> showDownloadChooser(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showChoiceSheet<String>(
    context,
    title: l10n.downloadAs,
    glyph: FinGlyph.download,
    options: [
      ChoiceOption(
        value: 'pdf',
        label: l10n.pdf,
        subtitle: 'Branded, print-ready',
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFFEF4444),
      ),
      ChoiceOption(
        value: 'csv',
        label: l10n.csv,
        subtitle: 'Open in Excel / Sheets',
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF16A34A),
      ),
    ],
  );
}
