import 'package:flutter/material.dart';

class AppModeProvider extends ChangeNotifier {
  ThemeMode _currentMode = ThemeMode.dark;
  ThemeMode get currentMode => _currentMode;

  void setMode(ThemeMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
}
