import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';

/// Holds theme + language + onboarding flag, persisted to local storage.
/// Light theme is the default per requirements.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.locale,
    required this.onboardingDone,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool onboardingDone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? onboardingDone,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController(this._ref)
      : super(const AppSettings(
          themeMode: ThemeMode.light,
          locale: Locale('en'),
          onboardingDone: false,
        )) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final storage = _ref.read(localStorageProvider);
    final themeStr = storage.getString(AppConstants.kThemeMode);
    final localeStr = storage.getString(AppConstants.kLocale);
    state = AppSettings(
      themeMode: _themeFromString(themeStr),
      locale: Locale(localeStr ?? 'en'),
      onboardingDone: storage.getBool(AppConstants.kOnboardingDone),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _ref
        .read(localStorageProvider)
        .setString(AppConstants.kThemeMode, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _ref
        .read(localStorageProvider)
        .setString(AppConstants.kLocale, locale.languageCode);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _ref
        .read(localStorageProvider)
        .setBool(AppConstants.kOnboardingDone, true);
  }

  ThemeMode _themeFromString(String? s) => switch (s) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>(
  (ref) => AppSettingsController(ref),
);
