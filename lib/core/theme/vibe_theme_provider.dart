import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';

/// Holds the currently active VibeTheme and notifies the entire widget tree
/// when the user changes it from the Profile screen.
class VibeThemeProvider extends ChangeNotifier {
  VibeTheme _current = VibeThemes.ceylonBlue;

  VibeTheme get current => _current;

  VibeThemeProvider() {
    _loadSaved();
  }

  void _loadSaved() {
    final profile = UserPreferenceService.getProfile();
    _current = VibeThemes.fromId(profile.vibeTheme);
  }

  /// Call this when the user taps a theme in the Profile picker.
  Future<void> setTheme(VibeTheme theme) async {
    _current = theme;
    notifyListeners(); // instantly updates the whole app
    // Persist to Hive
    final profile = UserPreferenceService.getProfile();
    profile.vibeTheme = theme.id;
    await UserPreferenceService.saveProfile(profile);
  }
}
