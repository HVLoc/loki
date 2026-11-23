import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local UI preferences (theme mode, locale, starter seed flag).
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyDarkMode = 'prefs_dark_mode';
  static const _keyLocale = 'prefs_locale';
  static const _keySeededUid = 'prefs_seeded_uid';

  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  String get localeCode => _prefs.getString(_keyLocale) ?? 'vi_VN';
  Future<void> setLocaleCode(String code) => _prefs.setString(_keyLocale, code);

  String? get seededUid => _prefs.getString(_keySeededUid);
  Future<void> setSeededUid(String uid) => _prefs.setString(_keySeededUid, uid);
}
