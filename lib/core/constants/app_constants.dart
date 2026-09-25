/// App-wide magic strings & keys in one place.
class AppConstants {
  AppConstants._();

  static const String appName = 'Apna Ledger';
  static const String tagline = 'Rakhe Pai Pai Ka Hisaab';
  static const String packageName = 'com.appexbusiness.apnaledger';

  // ---- SharedPreferences keys ----
  static const String kSessionUser = 'session_user';
  static const String kOnboardingDone = 'onboarding_done';
  static const String kThemeMode = 'theme_mode';
  static const String kLocale = 'locale';
  static const String kUsersBox = 'users_box'; // local user store (demo backend)

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
