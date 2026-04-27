import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isHighContrast = false;
  bool _isLargerText = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isHighContrast => _isHighContrast;
  bool get isLargerText => _isLargerText;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isLoaded => _isLoaded;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.darkModeEnabled) ?? false;
    _isHighContrast =
        prefs.getBool(AppConstants.highContrastEnabled) ?? false;
    _isLargerText = prefs.getBool(AppConstants.largerTextEnabled) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled && _isLoaded) {
      return;
    }

    _isDarkMode = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.darkModeEnabled, enabled);
  }

  Future<void> setHighContrast(bool enabled) async {
    if (_isHighContrast == enabled && _isLoaded) {
      return;
    }

    _isHighContrast = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.highContrastEnabled, enabled);
  }

  Future<void> setLargerText(bool enabled) async {
    if (_isLargerText == enabled && _isLoaded) {
      return;
    }

    _isLargerText = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.largerTextEnabled, enabled);
  }





}