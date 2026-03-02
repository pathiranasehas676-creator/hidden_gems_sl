import 'package:flutter/material.dart';
import '../../data/datasources/user_preference_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final profile = UserPreferenceService.getProfile();
    if (profile.languageCode != null) {
      _locale = Locale(profile.languageCode!);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await UserPreferenceService.updateLanguage(languageCode);
    notifyListeners();
  }
}
