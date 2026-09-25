import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/di/injector.dart';
import 'core/services/messaging_service.dart';
import 'features/auth/presentation/providers/auth_controller.dart';

/// Shared startup for every flavor. Each `main_*.dart` supplies its own
/// [EnvConfig] and Firebase [FirebaseOptions]; everything else is identical.
///
/// Firebase failures are swallowed so the app still runs on the local backend
/// (the default) even before Firebase is fully configured for every platform.
Future<void> bootstrap({
  required EnvConfig env,
  FirebaseOptions? firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(env);

  FirebaseAnalytics? analytics;
  FirebaseCrashlytics? crashlytics;
  FirebaseFirestore? firestore;

  if (firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);

      if (env.enableAnalytics) {
        analytics = FirebaseAnalytics.instance;
      }

      // Crashlytics has no web implementation — guard it.
      if (env.enableCrashlytics && !kIsWeb) {
        crashlytics = FirebaseCrashlytics.instance;
        FlutterError.onError = crashlytics.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          crashlytics!.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Firestore requires an authenticated context (rules use request.auth).
      // We sign in anonymously; only if that succeeds do we use Firestore,
      // otherwise the app safely falls back to the local backend.
      if (kBackend == Backend.firebase) {
        try {
          final cred = await FirebaseAuth.instance.signInAnonymously();
          if (cred.user != null) {
            firestore = FirebaseFirestore.instance;
          }
        } catch (e) {
          debugPrint('Anonymous auth failed — using local backend: $e');
        }
      }

      // Push notifications (mobile). Web push needs a VAPID key + service
      // worker, so it's enabled separately once configured.
      if (!kIsWeb) {
        await MessagingService(FirebaseMessaging.instance).init();
      }
    } catch (e, st) {
      // Never block app start on Firebase; log and continue on local backend.
      debugPrint('Firebase init skipped/failed: $e\n$st');
    }
  }

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      crashlyticsProvider.overrideWithValue(crashlytics),
      analyticsProvider.overrideWithValue(analytics),
      firestoreProvider.overrideWithValue(firestore),
    ],
  );

  // Restore any persisted session before the first frame so the router lands
  // the user on the right screen immediately.
  await container.read(authControllerProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ApnaLedgerApp(),
    ),
  );
}
