import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks the user which format to download. Returns 'csv', 'pdf', or null.
Future<String?> showDownloadChooser(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.downloadAs,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.pdf),
            subtitle: const Text('Branded, print-ready'),
            onTap: () => Navigator.pop(context, 'pdf'),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.csv),
            subtitle: const Text('Open in Excel / Sheets'),
            onTap: () => Navigator.pop(context, 'csv'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
