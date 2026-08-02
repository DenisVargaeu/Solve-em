library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AiSettings> loadAiSettings() async {
    final provider = AiProvider.fromId(
      _prefs.getString(AppConstants.prefsKeyProvider),
    );
    return AiSettings(
      provider: provider,
      apiKey: _prefs.getString(AppConstants.prefsKeyApiKey) ?? '',
      model:
          _prefs.getString(AppConstants.prefsKeyModel) ??
          AppConstants.defaultModelByProvider[provider.id] ??
          AppConstants.defaultModel,
      baseUrl: _prefs.getString(AppConstants.prefsKeyBaseUrl) ?? '',
    );
  }

  @override
  Future<void> saveAiSettings(AiSettings settings) async {
    await _prefs.setString(AppConstants.prefsKeyProvider, settings.provider.id);
    await _prefs.setString(AppConstants.prefsKeyApiKey, settings.apiKey.trim());
    await _prefs.setString(AppConstants.prefsKeyModel, settings.model.trim());
    await _prefs.setString(
      AppConstants.prefsKeyBaseUrl,
      settings.baseUrl.trim(),
    );
  }

  @override
  Future<String> loadThemeMode() async =>
      _prefs.getString(AppConstants.prefsKeyThemeMode) ?? 'system';

  @override
  Future<void> saveThemeMode(String mode) async =>
      _prefs.setString(AppConstants.prefsKeyThemeMode, mode);

  @override
  Future<bool> loadOcrEnabled() async =>
      _prefs.getBool(AppConstants.prefsKeyOcrEnabled) ?? true;

  @override
  Future<void> saveOcrEnabled(bool enabled) async =>
      _prefs.setBool(AppConstants.prefsKeyOcrEnabled, enabled);

  @override
  Future<double> loadTextScale() async =>
      _prefs.getDouble(AppConstants.prefsKeyTextScale) ?? 1.0;

  @override
  Future<void> saveTextScale(double scale) async =>
      _prefs.setDouble(AppConstants.prefsKeyTextScale, scale);

  @override
  Future<bool> loadReduceMotion() async =>
      _prefs.getBool(AppConstants.prefsKeyReduceMotion) ?? false;

  @override
  Future<void> saveReduceMotion(bool enabled) async =>
      _prefs.setBool(AppConstants.prefsKeyReduceMotion, enabled);
}
