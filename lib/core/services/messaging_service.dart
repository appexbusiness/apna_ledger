import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles a background/terminated push. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep light — the OS may kill the isolate quickly. Detailed handling should
  // happen when the app is opened from the notification.
  debugPrint('BG push: ${message.messageId}');
}

/// Thin wrapper around Firebase Cloud Messaging: permission, token, and a
/// foreground listener. All calls are guarded so a missing/incomplete native
/// setup never crashes the app.
class MessagingService {
  MessagingService(this._messaging);
  final FirebaseMessaging _messaging;

  Future<void> init() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FG push: ${message.notification?.title}');
        // A local-notifications package can render this in-app if desired.
      });
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('Messaging init skipped: $e');
    }
  }
}
