import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper so screens depend on our API, not Firebase directly.
/// Swappable/mockable in tests — pass a null [analytics] to no-op.
class AnalyticsService {
  AnalyticsService(this._analytics, {this.enabled = true});

  final FirebaseAnalytics? _analytics;
  final bool enabled;

  Future<void> logScreen(String name) async {
    if (!enabled) return;
    await _analytics?.logScreenView(screenName: name);
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (!enabled) return;
    await _analytics?.logEvent(name: name, parameters: params);
  }

  Future<void> setUser(String? userId) async {
    if (!enabled) return;
    await _analytics?.setUserId(id: userId);
  }
}
