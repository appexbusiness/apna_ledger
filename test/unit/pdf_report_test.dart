import 'dart:io';

import 'package:apna_ledger/core/services/export_service.dart';
import 'package:apna_ledger/core/services/ledger_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a realistic multi-page statement. Set PDF_OUT to also write the
/// file (used to eyeball the layout).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ledger PDF report builds with branding, insights and table', () async {
    final now = DateTime(2026, 9, 26, 18, 30);
    const cats = ['Food', 'Business', 'Family', 'Travel', 'Bills', 'Shopping'];
    final entries = <ReportEntry>[
      for (var i = 0; i < 70; i++)
        ReportEntry(
          date: now.subtract(Duration(days: i * 2, hours: i % 5)),
          typeKey: switch (i % 7) {
            0 || 3 => 'income',
            5 => 'loanGiven',
            6 => 'loanTaken',
            _ => 'expense',
          },
          category: cats[i % cats.length],
          subCategory: i % 4 == 0 ? 'Xerox Business' : '',
          amount: 350.0 + (i * 137) % 9000,
          note: i % 3 == 0 ? 'Monthly payment #$i' : '',
          person: i % 7 >= 5 ? 'Ravi Kumar' : '',
          recurring: i % 10 == 0,
        ),
    ];
    final report = LedgerReport(
      title: 'Ledger history',
      from: DateTime(2026, 5, 26),
      to: now,
      generatedAt: now,
      preparedFor: 'Asha Patel',
      entries: entries,
    );

    final bytes = await const ExportService().buildPdfReport(report);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(20000)); // includes embedded logos

    final out = Platform.environment['PDF_OUT'];
    if (out != null) await File(out).writeAsBytes(bytes);
  });
}
