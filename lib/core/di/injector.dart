import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env_config.dart';
import '../config/flavor.dart';
import '../constants/app_constants.dart';
import '../services/analytics_service.dart';
import '../services/local_storage_service.dart';
import '../services/logger_service.dart';
import '../services/otp_service.dart';

import '../../features/auth/data/firestore_auth_repository.dart';
import '../../features/auth/data/local_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/transactions/data/firestore_transaction_repository.dart';
import '../../features/transactions/data/local_transaction_repository.dart';
import '../../features/transactions/domain/transaction_repository.dart';
import '../../features/categories/data/firestore_category_repository.dart';
import '../../features/categories/data/local_category_repository.dart';
import '../../features/categories/domain/category_repository.dart';

/// Which data backend the app runs against.
/// - `local` : SharedPreferences (works instantly, great for demos & tests)
/// - `firebase` : Firestore (production path)
///
/// Flip this to [Backend.firebase] once your Firebase flavors are configured.
enum Backend { local, firebase }

const kBackend = Backend.firebase;

// ---------------------------------------------------------------------------
// Infrastructure singletons — OVERRIDDEN in bootstrap() with real instances.
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('override in bootstrap'),
);

final crashlyticsProvider = Provider<FirebaseCrashlytics?>((_) => null);
final analyticsProvider = Provider<FirebaseAnalytics?>((_) => null);
final firestoreProvider = Provider<FirebaseFirestore?>((_) => null);

// ---------------------------------------------------------------------------
// Core services
// ---------------------------------------------------------------------------
final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(ref.watch(sharedPreferencesProvider)),
);

final loggerProvider = Provider<LoggerService>(
  (ref) => LoggerService(ref.watch(crashlyticsProvider)),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(analyticsProvider)),
);

// ---------------------------------------------------------------------------
// OTP (mobile verification)
// ---------------------------------------------------------------------------
/// SWAP THIS for [ProductionSmsGateway] (with your real 3rd-party OTP
/// provider's API key) once you're ready to send real SMS. Until then every
/// environment logs the code to the console instead of sending it, so QA can
/// keep testing without SMS costs.
final smsGatewayProvider =
    Provider<SmsGateway>((ref) => DebugConsoleSmsGateway());

/// QA builds additionally accept [AppConstants.qaMasterOtp] so testers can
/// finish OTP flows without SMS. Never enabled for UAT or production.
final otpServiceProvider = Provider<OtpService>(
  (ref) => OtpService(
    ref.watch(localStorageProvider),
    ref.watch(smsGatewayProvider),
    masterOtp: _isQaBuild() ? AppConstants.qaMasterOtp : null,
  ),
);

bool _isQaBuild() {
  try {
    return EnvConfig.instance.flavor == Flavor.qa;
  } on StateError {
    return false; // EnvConfig not initialised (e.g. unit tests)
  }
}

// ---------------------------------------------------------------------------
// Repositories (interface -> implementation, selected by [kBackend])
// ---------------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Cross-device auth via Firestore when Firebase is up (users keyed by phone);
  // otherwise fall back to the on-device demo store.
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(localStorageProvider);
  if (firestore != null) {
    return FirestoreAuthRepository(firestore, storage);
  }
  return LocalAuthRepository(storage);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (kBackend == Backend.firebase && firestore != null) {
    return FirestoreTransactionRepository(firestore);
  }
  return LocalTransactionRepository(ref.watch(localStorageProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (kBackend == Backend.firebase && firestore != null) {
    return FirestoreCategoryRepository(firestore);
  }
  return LocalCategoryRepository(ref.watch(localStorageProvider));
});
