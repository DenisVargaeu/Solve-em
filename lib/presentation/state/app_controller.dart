library;

import 'package:flutter/material.dart';

import '../../domain/repositories/settings_repository.dart';

/// Controls the app-wide theme mode (system / light / dark) and persists it.

class AppController extends ChangeNotifier {
  AppController(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Loads the persisted theme preference.
  Future<void> init() async {
    final saved = await _settingsRepository.loadThemeMode();
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  /// Sets and persists the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _settingsRepository.saveThemeMode(mode.name);
  }
}
