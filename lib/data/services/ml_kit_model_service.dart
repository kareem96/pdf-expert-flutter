import 'package:shared_preferences/shared_preferences.dart';

class MlKitModelService {
  static const String _modelPrefKey = 'has_downloaded_mlkit_model';

  Future<bool> isModelDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modelPrefKey) ?? false;
  }

  Future<void> setModelDownloaded(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modelPrefKey, status);
  }

  // Realistic simulated download for Google Play Services backend
  Future<void> downloadModel() async {
    // In actual Flutter implementation with google_mlkit_text_recognition,
    // the model is downloaded automatically when the first processImage is called
    // if it's not present. Here we simulate a 4-second delay to show progress in UI.
    await Future.delayed(const Duration(seconds: 4));
    await setModelDownloaded(true);
  }
}
