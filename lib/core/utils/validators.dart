/// Pure, unit-testable form validators. Return `null` when valid.
class Validators {
  Validators._();

  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add 1 number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
      return 'Add 1 special character';
    }
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$field is required';
    return null;
  }

  /// Maximum allowed amount: ₹1,00,00,000 (1 crore). Keeps the UI readable.
  static const double maxAmount = 10000000;

  static String? amount(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Amount is required';
    final parsed = double.tryParse(v);
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    if (parsed > maxAmount) return 'Max is ₹1,00,00,000';
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null; // optional
    if (!RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v)) {
      return 'Enter a valid email';
    }
    return null;
  }
}
