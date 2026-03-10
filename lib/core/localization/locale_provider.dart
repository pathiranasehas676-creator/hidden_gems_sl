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

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    await UserPreferenceService.updateLanguage(newLocale.languageCode);
    notifyListeners();
  }
}
