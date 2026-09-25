import 'package:flutter_test/flutter_test.dart';
import 'package:apna_ledger/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('money renders the rupee symbol', () {
      expect(Formatters.money(1000), contains('₹'));
    });

    test('signedMoney prefixes minus for negatives', () {
      expect(Formatters.signedMoney(-50).startsWith('-'), isTrue);
    });

    test('signedMoney prefixes plus for positives', () {
      expect(Formatters.signedMoney(50).startsWith('+'), isTrue);
    });

    test('fullDate formats a known date', () {
      expect(Formatters.fullDate(DateTime(2026, 1, 5)), '5 Jan 2026');
    });
  });
}
