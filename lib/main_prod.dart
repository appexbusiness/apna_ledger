import 'bootstrap.dart';
import 'core/config/env_config.dart';
import 'core/config/flavor.dart';
import 'firebase_options_prod.dart';

/// Production entrypoint:  flutter run --flavor prod -t lib/main_prod.dart
///
/// Uses the separate production Firebase project. Fill in
/// firebase_options_prod.dart via `flutterfire configure` before release.
void main() => bootstrap(
      env: const EnvConfig(
        flavor: Flavor.prod,
        appName: 'Apna Ledger',
        enableCrashlytics: true,
        enableAnalytics: true,
      ),
      firebaseOptions: FirebaseOptionsProd.currentPlatform,
    );
