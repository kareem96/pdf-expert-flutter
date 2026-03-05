import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const _keyLastSaveDir = 'last_save_directory';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguageCode = 'language_code';

  Future<void> setLastSaveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSaveDir, path);
  }

  Future<String?> getLastSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastSaveDir);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode);
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguageCode, code);
  }

  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguageCode);
  }
}
