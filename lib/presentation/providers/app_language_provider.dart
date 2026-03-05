import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/app_preferences_service.dart';
import '../../common/constants/app_strings.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  final _prefs = AppPreferencesService();

  LanguageNotifier() : super(const Locale('id')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final code = await _prefs.getLanguageCode() ?? 'id';
    setLanguage(code);
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    AppStrings.setLanguage(code);
    await _prefs.setLanguageCode(code);
  }
}
