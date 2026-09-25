import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'file_saver.dart';

/// Builds CSV/PDF files and hands them to the user: a browser download on web,
/// the native share sheet (Save to Files / share) on mobile. Both formats carry
/// AppexBusiness branding.
class ExportService {
  const ExportService();

  static const _brand = 'AppexBusiness';
  static const _product = 'Apna Ledger';

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
      ..writeln('# $_product by $_brand')
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

  Future<Uint8List> _buildPdf(
    String title,
    List<String> header,
    List<List<Object?>> rows,
  ) async {
    final doc = pw.Document(
      title: '$_product — $title',
      author: _brand,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF0F766E), width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(_product,
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0F766E))),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('by $_brand',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    DateTime.now().toString().split('.').first,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}  ·  $_product by $_brand',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) {
          // Summary: transaction count + net total (amount is column index 6).
          double net = 0;
          for (final r in rows) {
            net += double.tryParse((r.length > 6 ? r[6] : '0').toString()) ?? 0;
          }
          final netStr =
              '${net < 0 ? '-' : '+'}Rs ${net.abs().toStringAsFixed(2)}';
          return [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F4F6),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Transactions: ${rows.length}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Net: $netStr',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(
                              net < 0 ? 0xFFE5484D : 0xFF15803D))),
                ],
              ),
            ),
            pw.Table.fromTextArray(
              headers: header,
              data: rows
                  .map((r) => r.map((c) => (c ?? '').toString()).toList())
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F766E)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              oddRowDecoration:
                  pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
              columnWidths: {6: pw.FlexColumnWidth(1.2)},
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<String> sharePdf({
    required String fileName,
    required String title,
    required List<String> header,
    required List<List<Object?>> rows,
    String? subject,
  }) async {
    final bytes = await _buildPdf(title, header, rows);
    return saveBytes(fileName, bytes, 'application/pdf');
  }
}
