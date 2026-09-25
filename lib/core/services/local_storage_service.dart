import 'package:shared_preferences/shared_preferences.dart';

/// Small typed wrapper around SharedPreferences. Keeps key access in one place.
class LocalStorageService {
  LocalStorageService(this._prefs);
  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool def = false}) => _prefs.getBool(key) ?? def;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
