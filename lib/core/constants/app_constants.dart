/// App-wide magic strings & keys in one place.
class AppConstants {
  AppConstants._();

  static const String appName = 'Apna Ledger';
  static const String tagline = 'Rakhe Pai Pai Ka Hisaab';

  /// Brand slogan + hashtag. Kept in English in every language on purpose —
  /// they are part of the brand mark, not UI copy.
  static const String slogan = "Track it. Don't guess it";
  static const String hashtag = '#Rakhe Pai Pai Ka Hisaab';

  static const String logoAsset = 'assets/branding/logo_transparent.png';
  static const String appexLogoAsset = 'assets/branding/appex_logo.png';

  /// Accepted as the OTP in QA builds only (alongside the real code), so QA
  /// can run the full sign-up / reset flows without SMS.
  static const String qaMasterOtp = '908212';
  static const String packageName = 'com.appexbusiness.apnaledger';

  // ---- SharedPreferences keys ----
  static const String kSessionUser = 'session_user';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'locale';
  static const String kUsersBox =
      'users_box'; // local user store (demo backend)

  // ---- Firestore collections ----
  static const String cUsers = 'users';
  static const String cTransactions = 'transactions';
  static const String cCategories = 'categories';

  static const List<String> supportedLocales = [
    'en',
    'hi',
    'gu',
    'bn',
    'te',
    'ta',
  ];
}
