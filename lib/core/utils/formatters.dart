import 'package:intl/intl.dart';

/// Currency + date formatting. Defaults to INR / en_IN grouping (lakh/crore).
class Formatters {
  Formatters._();

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compact =
      NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  static final NumberFormat _whole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String money(num value) => _inr.format(value);
  static String moneyWhole(num value) => _whole.format(value);
  static String moneyCompact(num value) => _compact.format(value);

  static String signedMoney(num value) {
    final sign = value < 0 ? '- ' : '+ ';
    return '$sign${_inr.format(value.abs())}';
  }

  /// Signed whole-rupee, e.g. "+₹27,300" / "-₹2,100".
  static String signedWhole(num value) {
    final sign = value < 0 ? '-' : '+';
    return '$sign${_whole.format(value.abs())}';
  }

  /// "Smart" money: compact (₹5.5Cr) for very large values so the UI never
  /// overflows, whole-rupee otherwise.
  static String moneySmart(num value) =>
      value.abs() >= 10000000 ? _compact.format(value) : _whole.format(value);

  static String signedSmart(num value) {
    final sign = value < 0 ? '-' : '+';
    final abs = value.abs();
    final body = abs >= 10000000 ? _compact.format(abs) : _whole.format(abs);
    return '$sign$body';
  }

  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
  static String fullDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String weekday(DateTime d) => DateFormat('EEE').format(d); // Mon
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  /// "21 Sep · Mon · 6:41 PM"
  static String dateDayTime(DateTime d) =>
      '${dayMonth(d)} · ${weekday(d)} · ${time(d)}';
}
