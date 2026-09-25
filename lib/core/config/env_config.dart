import 'flavor.dart';

/// Central, immutable environment configuration.
///
/// One instance is created per flavor in the `main_*.dart` entrypoints and then
/// exposed app-wide via [EnvConfig.instance]. Keeping every environment-specific
/// value here (never sprinkled through the codebase) is what makes the app easy
/// to maintain, test and extend.
class EnvConfig {
  const EnvConfig({
    required this.flavor,
    required this.appName,
    required this.enableCrashlytics,
    required this.enableAnalytics,
  });

  final Flavor flavor;
  final String appName;
  final bool enableCrashlytics;
  final bool enableAnalytics;

  static EnvConfig? _instance;
  static EnvConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'EnvConfig has not been initialised. Call EnvConfig.init() in main_*.dart.',
      );
    }
    return config;
  }

  static void init(EnvConfig config) => _instance = config;

  bool get isProd => flavor.isProduction;
}
