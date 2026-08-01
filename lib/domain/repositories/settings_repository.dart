library;

import '../entities/ai_settings.dart';

/// Persistence contract for user settings (API key, provider, theme…).

abstract interface class SettingsRepository {
  /// Reads the current AI settings.
  Future<AiSettings> loadAiSettings();

  /// Persists AI settings (API key, provider, model, base URL).
  Future<void> saveAiSettings(AiSettings settings);

  /// Reads the saved theme mode as a string ('system' | 'light' | 'dark').
  Future<String> loadThemeMode();

  /// Persists the theme mode.
  Future<void> saveThemeMode(String mode);

  /// Whether OCR was previously enabled.
  Future<bool> loadOcrEnabled();

  /// Persists the OCR enabled flag.
  Future<void> saveOcrEnabled(bool enabled);
}
