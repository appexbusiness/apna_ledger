import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design.dart';
import '../../../core/services/ledger_report.dart';
import '../../../core/services/saved_files.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/date_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/transaction.dart';
import 'providers/transaction_providers.dart';
import 'txn_csv.dart';
import 'txn_ui.dart';

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
  final toast = Toaster.of(context);
  final router = GoRouter.of(context);
  if (source.isEmpty) {
    toast.info(l10n.exportEmpty);
    return;
  }
  final opts = await showAppSheet<_DownloadOptions>(
    context,
    title: l10n.downloadOptions,
    subtitle: title,
    glyph: FinGlyph.download,
    builder: (context, _) => const _DownloadOptionsBody(),
  );
  if (opts == null || !context.mounted) return;

  final rows = source.where((t) {
    if (opts.types.isNotEmpty && !opts.types.contains(t.type)) return false;
    if (opts.from != null && t.date.isBefore(opts.from!)) return false;
    if (opts.to != null &&
        t.date.isAfter(
          DateTime(opts.to!.year, opts.to!.month, opts.to!.day, 23, 59, 59),
        )) {
      return false;
    }
    return true;
  }).toList();

  if (rows.isEmpty) {
    toast.info(l10n.exportEmpty);
    return;
  }

  try {
    final cats = ref.read(categoryByIdProvider);
    final csv = buildTxnCsv(rows, cats);
    final service = ref.read(exportServiceProvider);
    final ext = opts.format == 'pdf' ? 'pdf' : 'csv';
    // Timestamped so each export is kept (and listed in My downloads)
    // instead of overwriting the previous one.
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final name = '$fileBase-$stamp.$ext';
    if (opts.format == 'pdf') {
      final sorted = [...rows]..sort((a, b) => b.date.compareTo(a.date));
      await service.sharePdfReport(
        fileName: name,
        report: LedgerReport(
          title: title,
          from: opts.from,
          to: opts.to,
          generatedAt: DateTime.now(),
          preparedFor: ref.read(authControllerProvider)?.displayName,
          entries: [
            for (final t in sorted)
              ReportEntry(
                date: t.date,
                typeKey: t.type.key,
                category: cats[t.categoryId]?.name ?? '',
                subCategory: cats[t.categoryId]
                        ?.subCategories
                        .where((s) => s.id == t.subCategoryId)
                        .map((s) => s.name)
                        .firstOrNull ??
                    '',
                amount: t.amount,
                note: t.note,
                person: t.counterparty ?? '',
                recurring: t.isRecurring,
              ),
          ],
        ),
      );
    } else {
      await service.shareCsv(
        fileName: name,
        header: csv.header,
        rows: csv.rows,
      );
    }
    toast.success(
      canListSavedFiles ? '${l10n.downloadSaved} • $name' : l10n.downloadSaved,
      actionLabel: canListSavedFiles ? l10n.view : null,
      actionIcon: Icons.folder_open_rounded,
      onAction: () => router.push('/dashboard/downloads'),
    );
  } catch (_) {
    toast.error(
      l10n.somethingWrong,
      retryLabel: l10n.retry,
      onRetry: () {
        if (context.mounted) {
          runLedgerDownload(
            context,
            ref,
            source: source,
            fileBase: fileBase,
            title: title,
          );
        }
      },
    );
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

class _DownloadOptionsBody extends StatefulWidget {
  const _DownloadOptionsBody();

  @override
  State<_DownloadOptionsBody> createState() => _DownloadOptionsBodyState();
}

class _DownloadOptionsBodyState extends State<_DownloadOptionsBody> {
  String _format = 'pdf';
  final Set<TransactionType> _types = {};
  // Default range: the last 4 months up to today.
  int? _months = 4;
  late DateTime? _from = _monthsAgo(4);
  DateTime? _to = DateTime.now();

  static DateTime _monthsAgo(int m) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - m, now.day);
  }

  void _quick(int? months) => setState(() {
        _months = months;
        _from = months == null ? null : _monthsAgo(months);
        _to = months == null ? null : DateTime.now();
      });

  Future<void> _pick(bool from) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppDatePicker(
      context,
      initial: (from ? _from : _to) ?? DateTime.now(),
      first: DateTime(2015),
      last: DateTime(2100),
      title: from ? l10n.dateFrom : l10n.dateTo,
    );
    if (picked == null) return;
    setState(() {
      _months = -1; // custom range
      from ? _from = picked : _to = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semantic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupLabel(l10n.format, padding: const EdgeInsets.fromLTRB(4, 0, 4, 10)),
        Row(
          children: [
            Expanded(
              child: _FormatCard(
                label: l10n.pdf,
                caption: 'Branded, print-ready',
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFEF4444),
                selected: _format == 'pdf',
                onTap: () => setState(() => _format = 'pdf'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormatCard(
                label: l10n.csv,
                caption: 'Excel / Sheets',
                icon: Icons.table_chart_rounded,
                color: const Color(0xFF16A34A),
                selected: _format == 'csv',
                onTap: () => setState(() => _format = 'csv'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GroupLabel(l10n.types, padding: const EdgeInsets.fromLTRB(4, 0, 4, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TransactionType.values)
              TagChip(
                label: t.label(l10n),
                color: semantic.byTypeKey(t.key),
                selected: _types.contains(t),
                onTap: () => setState(
                  () => _types.contains(t) ? _types.remove(t) : _types.add(t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GroupLabel(l10n.dateRange,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in const [1, 4, 6, 12])
              TagChip(
                label: m == 12 ? '1Y' : '${m}M',
                selected: _months == m,
                onTap: () => _quick(m),
              ),
            TagChip(
              label: l10n.allDates,
              selected: _months == null,
              onTap: () => _quick(null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppPickerField(
                label: l10n.dateFrom,
                value: _from == null ? null : Formatters.fullDate(_from!),
                placeholder: l10n.anyDate,
                icon: Icons.event_rounded,
                onTap: () => _pick(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppPickerField(
                label: l10n.dateTo,
                value: _to == null ? null : Formatters.fullDate(_to!),
                placeholder: l10n.anyDate,
                icon: Icons.event_rounded,
                onTap: () => _pick(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.download,
          icon: Icons.download_rounded,
          onPressed: () => Navigator.pop(
            context,
            _DownloadOptions(
              format: _format,
              types: _types,
              from: _from,
              to: _to,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surfaces;
    return Pressable(
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      haptic: false,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? color.withValues(alpha: s.isDark ? 0.18 : 0.08) : s.card,
          border: Border.all(
            color: selected ? color : context.semantic.border,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? AppSurfaces.glow(color, strength: 0.4) : s.elevation(0.4),
        ),
        child: Row(
          children: [
            PopOnChange(
              trigger: selected,
              child: Icon3D(
                icon: icon,
                color: color,
                size: 40,
                style: selected ? Icon3DStyle.solid : Icon3DStyle.soft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15,),),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.semantic.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
