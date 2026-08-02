library;

import 'package:flutter/material.dart';

import '../../domain/repositories/settings_repository.dart';

/// Controls the app-wide theme mode, text scale and motion preferences.

class AppController extends ChangeNotifier {
  AppController(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  double _textScale = 1.0;
  double get textScale => _textScale;

  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;

  /// Loads the persisted appearance preferences.
  Future<void> init() async {
    final saved = await _settingsRepository.loadThemeMode();
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _textScale = await _settingsRepository.loadTextScale();
    _reduceMotion = await _settingsRepository.loadReduceMotion();
    notifyListeners();
  }

  /// Sets and persists the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _settingsRepository.saveThemeMode(mode.name);
  }

  /// Sets and persists the app-wide text scale factor.
  Future<void> setTextScale(double scale) async {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    await _settingsRepository.saveTextScale(scale);
  }

  /// Sets and persists the reduce-motion preference.
  Future<void> setReduceMotion(bool enabled) async {
    if (_reduceMotion == enabled) return;
    _reduceMotion = enabled;
    notifyListeners();
    await _settingsRepository.saveReduceMotion(enabled);
  }
}
