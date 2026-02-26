import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const _keyLastSaveDir = 'last_save_directory';

  Future<void> setLastSaveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSaveDir, path);
  }

  Future<String?> getLastSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastSaveDir);
  }
}
