import 'dart:developer' as dev;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/env_config.dart';

/// Issue severity, as requested — helps a developer triage from the console
/// and from Crashlytics custom keys.
enum IssueSeverity { low, mid, high }

extension IssueSeverityX on IssueSeverity {
  String get tag => switch (this) {
        IssueSeverity.low => 'LOW',
        IssueSeverity.mid => 'MID',
        IssueSeverity.high => 'HIGH',
      };
}

/// Single funnel for all app logging.
///
/// - Everything goes to the local console (dart:developer) with a severity tag.
/// - MID / HIGH issues (and all caught errors) are forwarded to Crashlytics as
///   non-fatal records with a `severity` custom key so they're filterable.
/// - HIGH errors can be marked fatal.
///
/// Usage:
///   logger.i('Login screen opened');
///   logger.log('Slow query', severity: IssueSeverity.mid);
///   logger.error(e, st, severity: IssueSeverity.high, reason: 'save txn');
class LoggerService {
  LoggerService(this._crashlytics);

  final FirebaseCrashlytics? _crashlytics;

  void i(String message, {String area = 'app'}) =>
      _console(message, area: area, severity: IssueSeverity.low);

  void log(
    String message, {
    String area = 'app',
    IssueSeverity severity = IssueSeverity.low,
  }) {
    _console(message, area: area, severity: severity);
    if (severity != IssueSeverity.low) {
      _crashlytics?.log('[${severity.tag}][$area] $message');
    }
  }

  void error(
    Object error,
    StackTrace? stack, {
    String reason = '',
    String area = 'app',
    IssueSeverity severity = IssueSeverity.high,
  }) {
    _console(
      'ERROR${reason.isEmpty ? '' : ' ($reason)'}: $error',
      area: area,
      severity: severity,
    );
    final crash = _crashlytics;
    if (crash == null) return;
    crash
      ..setCustomKey('severity', severity.tag)
      ..setCustomKey('area', area);
    crash.recordError(
      error,
      stack,
      reason: reason,
      fatal: severity == IssueSeverity.high,
    );
  }

  void _console(String message,
      {required String area, required IssueSeverity severity}) {
    dev.log(message, name: '${severity.tag}/$area');
    // Guard against noisy prod logs for low-severity messages.
    if (EnvConfig.instance.isProd && severity == IssueSeverity.low) return;
  }
}
