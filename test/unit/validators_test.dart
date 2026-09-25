import 'package:flutter_test/flutter_test.dart';
import 'package:apna_ledger/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts a valid 10-digit Indian mobile', () {
      expect(Validators.phone('9876543210'), isNull);
    });
    test('rejects numbers starting below 6', () {
      expect(Validators.phone('1234567890'), isNotNull);
    });
    test('rejects wrong length', () {
      expect(Validators.phone('98765'), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.phone(''), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts 6+ chars', () => expect(Validators.password('secret'), isNull));
    test('rejects short', () => expect(Validators.password('123'), isNotNull));
  });

  group('Validators.amount', () {
    test('accepts positive', () => expect(Validators.amount('250'), isNull));
    test('rejects zero', () => expect(Validators.amount('0'), isNotNull));
    test('rejects non-numeric', () => expect(Validators.amount('abc'), isNotNull));
  });

  group('Validators.email', () {
    test('empty is allowed (optional)', () => expect(Validators.email(''), isNull));
    test('valid passes', () => expect(Validators.email('a@b.com'), isNull));
    test('invalid fails', () => expect(Validators.email('nope'), isNotNull));
  });
}
