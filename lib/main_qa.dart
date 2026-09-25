import 'bootstrap.dart';
import 'core/config/env_config.dart';
import 'core/config/flavor.dart';
import 'firebase_options_qa.dart';

/// QA entrypoint:  flutter run --flavor qa -t lib/main_qa.dart
void main() => bootstrap(
      env: const EnvConfig(
        flavor: Flavor.qa,
        appName: 'Apna Ledger QA',
        enableCrashlytics: true,
        enableAnalytics: true,
      ),
      firebaseOptions: FirebaseOptionsQa.currentPlatform,
    );
