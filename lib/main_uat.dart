import 'bootstrap.dart';
import 'core/config/env_config.dart';
import 'core/config/flavor.dart';
import 'firebase_options_qa.dart';

/// UAT entrypoint:  flutter run --flavor uat -t lib/main_uat.dart
///
/// UAT shares the QA Firebase project (apnaledgerqa) per requirements, so it
/// reuses [FirebaseOptionsQa].
void main() => bootstrap(
      env: const EnvConfig(
        flavor: Flavor.uat,
        appName: 'Apna Ledger UAT',
        enableCrashlytics: true,
        enableAnalytics: true,
      ),
      firebaseOptions: FirebaseOptionsQa.currentPlatform,
    );
