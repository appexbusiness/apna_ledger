// Default entrypoint for quick starts (e.g. `flutter run -d chrome`) and web,
// where build flavors aren't required. It mirrors the QA environment.
//
// For real device/store builds use the flavored entrypoints instead:
//   flutter run --flavor qa   -t lib/main_qa.dart
//   flutter run --flavor uat  -t lib/main_uat.dart
//   flutter run --flavor prod -t lib/main_prod.dart
import 'bootstrap.dart';
import 'core/config/env_config.dart';
import 'core/config/flavor.dart';
import 'firebase_options_qa.dart';

void main() => bootstrap(
      env: const EnvConfig(
        flavor: Flavor.qa,
        appName: 'Apna Ledger',
        enableCrashlytics: true,
        enableAnalytics: true,
      ),
      firebaseOptions: FirebaseOptionsQa.currentPlatform,
    );
