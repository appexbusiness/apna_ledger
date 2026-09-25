import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/transaction.dart';
import 'providers/transaction_providers.dart';
import 'txn_csv.dart';

/// One entry point for every "download" button: shows options (format + date
/// range + types), filters, then saves the file directly.
Future<void> runLedgerDownload(
  BuildContext context,
  WidgetRef ref, {
  required List<TxnEntry> source,
  required String fileBase,
  required String title,
}) async {
  final l10n = AppLocalizations.of(context);
  if (source.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
    return;
  }
  final opts = await showModalBottomSheet<_DownloadOptions>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DownloadOptionsSheet(),
  );
  if (opts == null || !context.mounted) return;

  final rows = source.where((t) {
    if (opts.types.isNotEmpty && !opts.types.contains(t.type)) return false;
    if (opts.from != null && t.date.isBefore(opts.from!)) return false;
    if (opts.to != null &&
        t.date.isAfter(DateTime(opts.to!.year, opts.to!.month, opts.to!.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }).toList();

  if (rows.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
    return;
  }

  final cats = ref.read(categoryByIdProvider);
  final csv = buildTxnCsv(rows, cats);
  final service = ref.read(exportServiceProvider);
  final ext = opts.format == 'pdf' ? 'pdf' : 'csv';
  final location = opts.format == 'pdf'
      ? await service.sharePdf(
          fileName: '$fileBase.$ext',
          title: title,
          header: csv.header,
          rows: csv.rows)
      : await service.shareCsv(
          fileName: '$fileBase.$ext', header: csv.header, rows: csv.rows);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${l10n.download} • $location')));
  }
}

class _DownloadOptions {
  const _DownloadOptions({
    required this.format,
    required this.types,
    this.from,
    this.to,
  });
  final String format;
  final Set<TransactionType> types;
  final DateTime? from;
  final DateTime? to;
}

class _DownloadOptionsSheet extends StatefulWidget {
  @override
  State<_DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<_DownloadOptionsSheet> {
  String _format = 'pdf';
  final Set<TransactionType> _types = {};
  late DateTime? _from =
      DateTime.now().subtract(const Duration(days: 90));
  late DateTime? _to = DateTime.now();

  Future<void> _pick(bool from) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => from ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;
    String typeLabel(TransactionType t) {
      switch (t) {
        case TransactionType.income:
          return l10n.income;
        case TransactionType.expense:
          return l10n.spending;
        case TransactionType.loanGiven:
          return l10n.loanGiven;
        case TransactionType.loanTaken:
          return l10n.loanTaken;
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.downloadOptions,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(l10n.format, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                  value: 'pdf',
                  label: Text(l10n.pdf),
                  icon: const Icon(Icons.picture_as_pdf_outlined)),
              ButtonSegment(
                  value: 'csv',
                  label: Text(l10n.csv),
                  icon: const Icon(Icons.table_chart_outlined)),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 16),
          Text(l10n.types, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TransactionType.values)
                FilterChip(
                  label: Text(typeLabel(t)),
                  selected: _types.contains(t),
                  onSelected: (v) => setState(
                      () => v ? _types.add(t) : _types.remove(t)),
                  selectedColor:
                      semantic.byTypeKey(t.key).withValues(alpha: 0.18),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(true),
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                      _from == null ? l10n.dateFrom : Formatters.dayMonth(_from!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                      _to == null ? l10n.dateTo : Formatters.dayMonth(_to!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                _DownloadOptions(
                    format: _format, types: _types, from: _from, to: _to),
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.download),
            ),
          ),
        ],
      ),
    );
  }
}
