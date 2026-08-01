library;

import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Holds and persists the user's AI configuration (provider, key, model).
///
/// The API key is never logged, never placed in source code, and only stored
/// in [SettingsRepository] (SharedPreferences) after the user saves it.

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AiSettings _settings = const AiSettings();
  AiSettings get settings => _settings;

  bool _loaded = false;
  bool get loaded => _loaded;

  bool _ocrEnabled = true;
  bool get ocrEnabled => _ocrEnabled;

  /// Loads the saved configuration from storage.
  Future<void> init() async {
    _settings = await _repository.loadAiSettings();
    _ocrEnabled = await _repository.loadOcrEnabled();
    _loaded = true;
    notifyListeners();
  }

  /// Persists a new configuration.
  Future<void> save(AiSettings value) async {
    _settings = value;
    notifyListeners();
    await _repository.saveAiSettings(value);
  }

  /// Whether the user has entered a usable API key.
  bool get isConfigured => _settings.isConfigured;

  /// Updates a single field without persisting (used by edit forms).
  void update(AiSettings value) {
    _settings = value;
    notifyListeners();
  }

  String get providerLabel => _settings.provider.label;

  Future<void> clearApiKey() async {
    await save(_settings.copyWith(apiKey: ''));
  }

  /// Persists the on-device OCR toggle.
  Future<void> setOcrEnabled(bool value) async {
    _ocrEnabled = value;
    notifyListeners();
    await _repository.saveOcrEnabled(value);
  }
}
