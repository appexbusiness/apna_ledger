import 'dart:convert';
import 'dart:math';

import '../error/failure.dart';
import 'local_storage_service.dart';

/// Contract for the actual SMS/OTP delivery provider.
///
/// This is the ONE place to plug in a real 3rd-party OTP API (MSG91,
/// Fast2SMS, Twilio Verify, Firebase Phone Auth, etc). Implement [send] to
/// call that provider's REST API, then bind [SmsGateway] to your
/// implementation in `injector.dart` — nothing else in the app changes.
abstract interface class SmsGateway {
  /// Sends [code] to [phone] (10-digit, no country code). Throw on failure
  /// so [OtpService.sendOtp] can surface a clean error to the UI.
  Future<void> send({required String phone, required String code});
}

/// Development-only gateway: does not call any network API. It just logs the
/// code so QA/dev builds keep working before a real provider is wired up.
///
/// SWAP THIS OUT before shipping to production — see [ProductionSmsGateway].
class DebugConsoleSmsGateway implements SmsGateway {
  @override
  Future<void> send({required String phone, required String code}) async {
    // ignore: avoid_print
    print('[DEV OTP] +91$phone → $code (replace DebugConsoleSmsGateway with '
        'a real SmsGateway implementation before release)');
  }
}

/// Template for a real provider. Fill in [_endpoint]/[_apiKey] (from your
/// 3rd-party OTP vendor's dashboard) and the request shape their docs ask
/// for, then bind this instead of [DebugConsoleSmsGateway] for prod builds.
class ProductionSmsGateway implements SmsGateway {
  ProductionSmsGateway({required this.apiKey, required this.senderId});
  final String apiKey;
  final String senderId;

  @override
  Future<void> send({required String phone, required String code}) async {
    // TODO(auth): replace with the real HTTP call to your SMS provider, e.g.:
    //
    // final res = await http.post(
    //   Uri.parse('https://api.yourprovider.com/v1/sms/send'),
    //   headers: {'Authorization': 'Bearer $apiKey'},
    //   body: {
    //     'sender': senderId,
    //     'to': '+91$phone',
    //     'message': 'Your Apna Ledger verification code is $code. '
    //         'Valid for 5 minutes. Do not share this code.',
    //   },
    // );
    // if (res.statusCode != 200) {
    //   throw const AppFailure('otpSendFailed');
    // }
    throw const AppFailure(
      'otpSendFailed',
      cause: 'ProductionSmsGateway is not configured yet — set it up in '
          'injector.dart with your OTP provider\'s API key before going live.',
    );
  }
}

class OtpSendResult {
  const OtpSendResult({
    required this.remainingToday,
    required this.cooldownSeconds,
    required this.expiresInSeconds,
  });

  /// OTP sends this phone has left for today (out of [OtpService.maxPerDay]).
  final int remainingToday;

  /// Seconds to wait before "Resend" is allowed again.
  final int cooldownSeconds;

  /// Seconds until the just-sent code itself expires.
  final int expiresInSeconds;
}

/// Handles OTP generation, per-phone daily rate limiting, expiry and
/// verification. Deliberately independent of [AuthRepository] — it's used
/// for every phone-verification moment (new account, forgot password),
/// regardless of which auth backend (Firestore/local) is active.
class OtpService {
  OtpService(this._storage, this._gateway);

  final LocalStorageService _storage;
  final SmsGateway _gateway;

  static const int maxPerDay = 3;
  static const Duration codeValidity = Duration(minutes: 5);
  static const Duration resendCooldown = Duration(seconds: 30);

  static const _boxKey = 'otp_state_v1';

  Map<String, dynamic> _readAll() {
    final raw = _storage.getString(_boxKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> all) =>
      _storage.setString(_boxKey, jsonEncode(all));

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _hash(String code) => code; // stored locally only; not sensitive
  // (Kept as a separate method so a real backend can swap this for a
  // server-side hash/compare instead of client-side storage.)

  /// Sends a fresh OTP to [phone]. Throws [AppFailure('otpLimitReached')] once
  /// the daily cap (default 3) is hit, or [AppFailure('otpResendTooSoon')]
  /// if called again inside the cooldown window.
  Future<OtpSendResult> sendOtp(String phone) async {
    final all = _readAll();
    final entry = Map<String, dynamic>.from(
        (all[phone] as Map?)?.cast<String, dynamic>() ?? {});
    final today = _today();

    // Reset the counter when the day has rolled over.
    if (entry['day'] != today) {
      entry['day'] = today;
      entry['count'] = 0;
    }

    final count = (entry['count'] as int?) ?? 0;
    final lastSentAt = entry['lastSentAt'] as int?;
    if (lastSentAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastSentAt;
      final remainingCooldown =
          resendCooldown.inMilliseconds - elapsed;
      if (remainingCooldown > 0) {
        throw AppFailure('otpResendTooSoon',
            cause: (remainingCooldown / 1000).ceil());
      }
    }

    if (count >= maxPerDay) {
      throw const AppFailure('otpLimitReached');
    }

    final code = (100000 + Random.secure().nextInt(900000)).toString();
    final now = DateTime.now();

    try {
      await _gateway.send(phone: phone, code: code);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('otpSendFailed');
    }

    entry['count'] = count + 1;
    entry['lastSentAt'] = now.millisecondsSinceEpoch;
    entry['code'] = _hash(code);
    entry['expiresAt'] =
        now.add(codeValidity).millisecondsSinceEpoch;
    entry['attempts'] = 0;
    all[phone] = entry;
    await _writeAll(all);

    return OtpSendResult(
      remainingToday: maxPerDay - (count + 1),
      cooldownSeconds: resendCooldown.inSeconds,
      expiresInSeconds: codeValidity.inSeconds,
    );
  }

  /// How many sends are left today for [phone] without sending one.
  int remainingToday(String phone) {
    final all = _readAll();
    final entry = (all[phone] as Map?)?.cast<String, dynamic>();
    if (entry == null || entry['day'] != _today()) return maxPerDay;
    return (maxPerDay - ((entry['count'] as int?) ?? 0)).clamp(0, maxPerDay);
  }

  /// Verifies [code] against the last OTP sent to [phone]. Allows up to 5
  /// wrong attempts per sent code before requiring a fresh send.
  bool verifyOtp(String phone, String code) {
    final all = _readAll();
    final entry = (all[phone] as Map?)?.cast<String, dynamic>();
    if (entry == null) return false;

    final expiresAt = entry['expiresAt'] as int?;
    if (expiresAt == null ||
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return false;
    }

    final attempts = (entry['attempts'] as int?) ?? 0;
    if (attempts >= 5) return false;

    final storedCode = entry['code'] as String?;
    final ok = storedCode != null && storedCode == _hash(code.trim());
    if (ok) {
      entry.remove('code');
      entry.remove('expiresAt');
    } else {
      entry['attempts'] = attempts + 1;
    }
    all[phone] = entry;
    // Fire-and-forget: verification is a synchronous UI call.
    _writeAll(all);
    return ok;
  }
}
