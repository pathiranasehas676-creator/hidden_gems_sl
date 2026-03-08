import 'package:flutter/material.dart';
import '../../data/datasources/user_preference_service.dart';

class ScreenshotProvider extends ChangeNotifier {
  bool _isVisible = UserPreferenceService.getProfile().showScreenshotButton;
  bool get isVisible => _isVisible;

  void toggleVisibility(bool value) {
    _isVisible = value;
    UserPreferenceService.updateScreenshotMode(value);
    notifyListeners();
  }
}
