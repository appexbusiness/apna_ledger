import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/app_constants.dart';
import 'file_saver.dart';
import 'ledger_report.dart';

/// Builds CSV/PDF files and saves them for the user (browser download on
/// web; app folder + public Download/ApnaLedger on Android; Files app on
/// iOS). Both formats carry Apna Ledger × Appex Business branding.
class ExportService {
  const ExportService();

  static const _brand = 'Appex Business';
  static const _product = AppConstants.appName;

  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  static String _cell(Object? value) {
    final s = (value ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String buildCsv(List<String> header, List<List<Object?>> rows) {
    final buffer = StringBuffer()
      // Branding banner as leading comment rows.
      ..writeln('# $_product by $_brand - ${AppConstants.slogan}')
      ..writeln('# Generated ${DateTime.now().toIso8601String()}')
      ..writeln(header.map(_cell).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_cell).join(','));
    }
    return buffer.toString();
  }

  Future<String> shareCsv({
    required String fileName,
    required List<String> header,
    required List<List<Object?>> rows,
    String? subject,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(buildCsv(header, rows)));
    return saveBytes(fileName, bytes, 'text/csv');
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<String> sharePdfReport({
    required String fileName,
    required LedgerReport report,
  }) async {
    final bytes = await buildPdfReport(report);
    return saveBytes(fileName, bytes, 'application/pdf');
  }

  /// Builds the branded, insight-led ledger statement.
  Future<Uint8List> buildPdfReport(LedgerReport report) async {
    final logo = await _asset(AppConstants.logoAsset);
    final appex = await _asset(AppConstants.appexLogoAsset);
    final data = _Insights(report);

    final doc = pw.Document(
      title: '$_product - ${report.title}',
      author: _brand,
      creator: '$_product by $_brand',
      subject: AppConstants.slogan,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          buildBackground: (context) => _background(context, logo),
        ),
        header: (context) => context.pageNumber == 1
            ? _coverHeader(report, logo)
            : _slimHeader(report, logo),
        footer: (context) => _footer(context, appex),
        build: (context) => [
          pw.SizedBox(height: 18),
          _kpis(data),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(flex: 11, child: _topCategories(data)),
              pw.SizedBox(width: 14),
              pw.Expanded(flex: 9, child: _highlights(data)),
            ],
          ),
          if (data.months.length > 1) ...[
            pw.SizedBox(height: 16),
            _monthly(data),
          ],
          pw.SizedBox(height: 20),
          _sectionTitle(
            'All transactions',
            '${report.entries.length} entries · newest first',
          ),
          pw.SizedBox(height: 8),
          _table(report),
          pw.SizedBox(height: 18),
          _closingNote(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<pw.MemoryImage?> _asset(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null; // e.g. unit tests without the asset bundle
    }
  }

  // ---- Palette (solid, matching the app) ----
  static const _navy = PdfColor.fromInt(0xFF12304D);
  static const _navyDeep = PdfColor.fromInt(0xFF0A1729);
  static const _gold = PdfColor.fromInt(0xFFF5B82E);
  static const _goldDeep = PdfColor.fromInt(0xFFC98A0B);
  static const _teal = PdfColor.fromInt(0xFF0E9F8E);
  static const _ink = PdfColor.fromInt(0xFF0E1330);
  static const _muted = PdfColor.fromInt(0xFF6B7390);
  static const _line = PdfColor.fromInt(0xFFE2E6EF);
  static const _zebra = PdfColor.fromInt(0xFFF5F7FB);
  static const _income = PdfColor.fromInt(0xFF16A34A);
  static const _expense = PdfColor.fromInt(0xFFEF4444);
  static const _given = PdfColor.fromInt(0xFFF0A81C);
  static const _taken = PdfColor.fromInt(0xFF8B5CF6);

  static const double _coverBand = 150;
  static const double _slimBand = 54;
  static const double _footerBand = 50;

  static PdfColor _typeColor(String k) => switch (k) {
        'income' => _income,
        'loanGiven' => _given,
        'loanTaken' => _taken,
        _ => _expense,
      };

  static String _typeLabel(String k) => switch (k) {
        'income' => 'Income',
        'loanGiven' => 'Money given',
        'loanTaken' => 'Money taken',
        _ => 'Spending',
      };

  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );
  static final _moneyShort = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  static String _signed(double v) =>
      '${v < 0 ? '- ' : '+ '}${_money.format(v.abs())}';
  static final _date = DateFormat('d MMM yyyy');
  static final _dateShort = DateFormat('d MMM');

  // ---- Page chrome ----

  pw.Widget _background(pw.Context context, pw.MemoryImage? logo) {
    final first = context.pageNumber == 1;
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          // Faint watermark.
          if (logo != null)
            pw.Center(
              child: pw.Opacity(
                opacity: 0.035,
                child: pw.Image(logo, width: 330, height: 330),
              ),
            ),
          // Top band + gold rule.
          pw.Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: pw.Column(
              children: [
                pw.Container(
                  height: first ? _coverBand : _slimBand,
                  color: _navy,
                ),
                pw.Container(height: 3, color: _gold),
              ],
            ),
          ),
          // Footer band.
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Column(
              children: [
                pw.Container(height: 1.5, color: _gold),
                pw.Container(height: _footerBand, color: _navyDeep),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _coverHeader(LedgerReport r, pw.MemoryImage? logo) {
    final period = r.from == null && r.to == null
        ? 'All dates'
        : '${r.from == null ? 'Start' : _date.format(r.from!)}  to  '
            '${r.to == null ? 'Today' : _date.format(r.to!)}';
    return pw.Container(
      height: _coverBand + 3,
      padding: const pw.EdgeInsets.only(top: 22, bottom: 20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) pw.Image(logo, width: 84, height: 84),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  _product,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  AppConstants.slogan,
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.8),
                    fontSize: 10.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: _gold, width: 0.8),
                  ),
                  child: pw.Text(
                    AppConstants.hashtag,
                    style: const pw.TextStyle(
                      color: _gold,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'LEDGER STATEMENT',
                style: const pw.TextStyle(
                  color: _gold,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                r.title,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                period,
                style: const pw.TextStyle(
                  color: PdfColor(1, 1, 1, 0.85),
                  fontSize: 9.5,
                ),
              ),
              if ((r.preparedFor ?? '').isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Prepared for ${r.preparedFor}',
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.7),
                    fontSize: 8.5,
                  ),
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated ${DateFormat('d MMM yyyy, h:mm a').format(r.generatedAt)}',
                style: const pw.TextStyle(
                  color: PdfColor(1, 1, 1, 0.6),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _slimHeader(LedgerReport r, pw.MemoryImage? logo) {
    return pw.Container(
      height: _slimBand + 3,
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          if (logo != null) pw.Image(logo, width: 30, height: 30),
          pw.SizedBox(width: 8),
          pw.Text(
            _product,
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '  ·  ${r.title}',
            style: const pw.TextStyle(
              color: PdfColor(1, 1, 1, 0.75),
              fontSize: 10,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            AppConstants.hashtag,
            style: const pw.TextStyle(
              color: _gold,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context, pw.MemoryImage? appex) {
    return pw.Container(
      height: _footerBand + 1.5,
      padding: const pw.EdgeInsets.only(top: 1.5),
      child: pw.Row(
        children: [
          if (appex != null)
            pw.Container(
              width: 26,
              height: 26,
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(appex),
            ),
          pw.SizedBox(width: 8),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'A product of $_brand',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'www.appexbusiness.com',
                style: const pw.TextStyle(color: _gold, fontSize: 7.5),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Text(
            '${AppConstants.slogan}  ·  ${AppConstants.hashtag}',
            style: const pw.TextStyle(
              color: PdfColor(1, 1, 1, 0.65),
              fontSize: 7.5,
            ),
          ),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: _gold,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                color: _navyDeep,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Content blocks ----

  pw.Widget _sectionTitle(String title, [String? caption]) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(width: 4, height: 14, color: _gold),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: const pw.TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (caption != null) ...[
          pw.SizedBox(width: 8),
          pw.Text(caption, style: const pw.TextStyle(color: _muted, fontSize: 8.5)),
        ],
      ],
    );
  }

  pw.Widget _kpis(_Insights d) {
    pw.Widget card(String label, double v, int count, PdfColor c,
        {bool signed = false,}) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.fromLTRB(9, 8, 8, 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _line, width: 0.8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3,
                height: 34,
                decoration: pw.BoxDecoration(
                  color: c,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      label.toUpperCase(),
                      style: const pw.TextStyle(
                        color: _muted,
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.FittedBox(
                      child: pw.Text(
                        signed ? _signed(v) : _moneyShort.format(v),
                        style: pw.TextStyle(
                          color: c,
                          fontSize: 11.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '$count ${count == 1 ? 'entry' : 'entries'}',
                      style: const pw.TextStyle(color: _muted, fontSize: 6.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        card('Income', d.total('income'), d.count('income'), _income),
        card('Spending', d.total('expense'), d.count('expense'), _expense),
        card('Money given', d.total('loanGiven'), d.count('loanGiven'),
            _given,),
        card('Money taken', d.total('loanTaken'), d.count('loanTaken'),
            _taken,),
        card('Net flow', d.net, d.entries, d.net >= 0 ? _teal : _expense,
            signed: true,),
      ],
    );
  }

  pw.Widget _panel({required String title, required pw.Widget child}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  pw.Widget _topCategories(_Insights d) {
    final top = d.topSpending;
    if (top.isEmpty) {
      return _panel(
        title: 'Where your money went',
        child: pw.Text(
          'No spending in this period.',
          style: const pw.TextStyle(color: _muted, fontSize: 9),
        ),
      );
    }
    final max = top.first.value;
    const palette = [0xFF0E9F8E, 0xFFE9A20F, 0xFF3B82F6, 0xFFEF4444, 0xFF8B5CF6];
    return _panel(
      title: 'Where your money went',
      child: pw.Column(
        children: [
          for (var i = 0; i < top.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          top[i].key,
                          maxLines: 1,
                          style: const pw.TextStyle(
                            color: _ink,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${_moneyShort.format(top[i].value)}  ·  '
                        '${(top[i].value / d.total('expense') * 100).toStringAsFixed(0)}%',
                        style: const pw.TextStyle(color: _muted, fontSize: 8.5),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Stack(
                    children: [
                      pw.Container(
                        height: 6,
                        decoration: pw.BoxDecoration(
                          color: _zebra,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.LayoutBuilder(
                        builder: (context, box) => pw.Container(
                          width: math.max(
                            4,
                            (box?.maxWidth ?? 200) * top[i].value / max,
                          ),
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(palette[i % palette.length]),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _highlights(_Insights d) {
    pw.Widget row(String label, String value, {PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 4,
                height: 4,
                margin: const pw.EdgeInsets.only(top: 3, right: 6),
                decoration: const pw.BoxDecoration(
                  color: _gold,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  label,
                  style: const pw.TextStyle(color: _muted, fontSize: 8.5),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  color: color ?? _ink,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

    final rate = d.savingsRate;
    return _panel(
      title: 'Highlights',
      child: pw.Column(
        children: [
          row(
            'Savings rate',
            rate == null ? '-' : '${(rate * 100).toStringAsFixed(0)}%',
            color: rate == null
                ? null
                : (rate >= 0.1 ? _income : (rate >= 0 ? _goldDeep : _expense)),
          ),
          row('Average daily spend', _moneyShort.format(d.avgDailySpend)),
          if (d.largestSpend != null)
            row(
              'Largest spend',
              '${_moneyShort.format(d.largestSpend!.amount)} · '
                  '${d.largestSpend!.category}, '
                  '${_dateShort.format(d.largestSpend!.date)}',
              color: _expense,
            ),
          if (d.largestIncome != null)
            row(
              'Largest income',
              '${_moneyShort.format(d.largestIncome!.amount)} · '
                  '${_dateShort.format(d.largestIncome!.date)}',
              color: _income,
            ),
          if (d.busiestDay != null) row('Busiest day', d.busiestDay!),
          row(
            'Lent vs borrowed',
            _signed(d.total('loanGiven') - d.total('loanTaken')),
          ),
          row('Recurring entries', '${d.recurring}'),
        ],
      ),
    );
  }

  pw.Widget _monthly(_Insights d) {
    final months = d.months;
    final maxV = months.fold<double>(
      1,
      (m, e) => math.max(m, math.max(e.income, e.spend)),
    );
    const barH = 70.0;
    pw.Widget bar(double v, PdfColor c) => pw.Container(
          width: 9,
          height: math.max(1.5, barH * v / maxV),
          decoration: pw.BoxDecoration(
            color: c,
            borderRadius: const pw.BorderRadius.vertical(
              top: pw.Radius.circular(2),
            ),
          ),
        );
    pw.Widget legend(String l, PdfColor c) => pw.Row(
          children: [
            pw.Container(width: 7, height: 7, color: c),
            pw.SizedBox(width: 3),
            pw.Text(l, style: const pw.TextStyle(color: _muted, fontSize: 7.5)),
          ],
        );

    return _panel(
      title: 'Monthly movement',
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              legend('Income', _income),
              pw.SizedBox(width: 10),
              legend('Spending', _expense),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              for (final m in months.take(12))
                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        bar(m.income, _income),
                        pw.SizedBox(width: 2),
                        bar(m.spend, _expense),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      DateFormat('MMM yy').format(m.month),
                      style: const pw.TextStyle(color: _muted, fontSize: 7),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _table(LedgerReport r) {
    pw.Widget cell(
      String text, {
      PdfColor? color,
      bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
      double size = 8,
    }) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              color: color ?? _ink,
              fontSize: size,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    pw.Widget head(String t, [pw.TextAlign a = pw.TextAlign.left]) =>
        cell(t, color: PdfColors.white, bold: true, align: a, size: 7.5);

    pw.Widget pill(String key) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
              color: _typeColor(key),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              _typeLabel(key),
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(58),
        1: pw.FixedColumnWidth(64),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(2.6),
        4: pw.FixedColumnWidth(78),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            head('DATE'),
            head('TYPE'),
            head('CATEGORY'),
            head('NOTE / PERSON'),
            head('AMOUNT', pw.TextAlign.right),
          ],
        ),
        for (var i = 0; i < r.entries.length; i++)
          () {
            final e = r.entries[i];
            final detail = [
              if (e.note.isNotEmpty) e.note,
              if (e.person.isNotEmpty) e.person,
              if (e.recurring) 'Recurring',
            ].join(' · ');
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isOdd ? _zebra : PdfColors.white,
              ),
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                cell(
                  '${_dateShort.format(e.date)}\n${DateFormat('EEE').format(e.date)}',
                  size: 7.5,
                ),
                pill(e.typeKey),
                cell(
                  e.subCategory.isEmpty
                      ? e.category
                      : '${e.category} / ${e.subCategory}',
                  bold: true,
                ),
                cell(detail.isEmpty ? '-' : detail, color: _muted),
                cell(
                  _signed(e.signed),
                  color: _typeColor(e.typeKey),
                  bold: true,
                  align: pw.TextAlign.right,
                ),
              ],
            );
          }(),
      ],
    );
  }

  pw.Widget _closingNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: _zebra,
        // Non-uniform border: corners must stay square.
        border: pw.Border(left: pw.BorderSide(color: _gold, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${AppConstants.slogan}.',
            style: const pw.TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'This statement is generated from the entries you recorded in '
            '$_product. It is a personal record, not a bank statement. '
            'Amounts are in Indian Rupees.',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

/// Pure calculations behind the report's cards and highlights.
class _Insights {
  _Insights(this.report) {
    for (final e in report.entries) {
      _totals.update(e.typeKey, (v) => v + e.amount, ifAbsent: () => e.amount);
      _counts.update(e.typeKey, (v) => v + 1, ifAbsent: () => 1);
      if (e.recurring) recurring++;
      if (e.typeKey == 'expense') {
        _byCategory.update(
          e.category.isEmpty ? '-' : e.category,
          (v) => v + e.amount,
          ifAbsent: () => e.amount,
        );
        if (largestSpend == null || e.amount > largestSpend!.amount) {
          largestSpend = e;
        }
      }
      if (e.typeKey == 'income' &&
          (largestIncome == null || e.amount > largestIncome!.amount)) {
        largestIncome = e;
      }
      final m = DateTime(e.date.year, e.date.month);
      final bucket = _months.putIfAbsent(m, () => _Month(m));
      if (e.typeKey == 'income') bucket.income += e.amount;
      if (e.typeKey == 'expense') bucket.spend += e.amount;
      _weekdays.update(e.date.weekday, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  final LedgerReport report;
  final _totals = <String, double>{};
  final _counts = <String, int>{};
  final _byCategory = <String, double>{};
  final _months = <DateTime, _Month>{};
  final _weekdays = <int, int>{};
  int recurring = 0;
  ReportEntry? largestSpend;
  ReportEntry? largestIncome;

  double total(String k) => _totals[k] ?? 0;
  int count(String k) => _counts[k] ?? 0;
  int get entries => report.entries.length;
  double get net => report.entries.fold(0.0, (s, e) => s + e.signed);

  double? get savingsRate {
    final inc = total('income');
    if (inc <= 0) return null;
    return (inc - total('expense')) / inc;
  }

  List<MapEntry<String, double>> get topSpending {
    final list = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  List<_Month> get months =>
      _months.values.toList()..sort((a, b) => a.month.compareTo(b.month));

  double get avgDailySpend {
    if (report.entries.isEmpty) return 0;
    final dates = report.entries.map((e) => e.date);
    final first = report.from ?? dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final last = report.to ?? dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final days = math.max(1, last.difference(first).inDays + 1);
    return total('expense') / days;
  }

  String? get busiestDay {
    if (_weekdays.isEmpty) return null;
    final top = _weekdays.entries.reduce((a, b) => a.value >= b.value ? a : b);
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${names[top.key - 1]} (${top.value})';
  }
}

class _Month {
  _Month(this.month);
  final DateTime month;
  double income = 0;
  double spend = 0;
}
