import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/flavor_banner.dart';
import '../features/settings/presentation/app_settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';

/// Root application widget. Theme + locale are reactive to [appSettingsProvider]
/// so changing them anywhere updates the whole app instantly.
class ApnaLedgerApp extends ConsumerWidget {
  const ApnaLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          FlavorBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
