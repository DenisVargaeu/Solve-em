library;

/// Global application constants.
///
/// Kept in one place so the rest of the app never has to repeat magic
/// strings or numbers. **No API keys live here** — keys are always provided
/// by the user at runtime through the Settings screen.

abstract final class AppConstants {
  AppConstants._();

  /// Application display name.
  static const String appName = "Solve 'em";

  /// Short tagline used on the home screen and empty states.
  static const String tagline = 'Snap it. Understand it. Master it.';

  /// Current app version, shown in Settings.
  static const String appVersion = '1.5.0';

  /// Storage key of the Hive box that persists solved problems.
  static const String problemsBoxName = 'problems';

  /// Storage key of the Hive box that persists math notes.
  static const String notesBoxName = 'notes';

  /// SharedPreferences keys — never touch raw string literals elsewhere.
  static const String prefsKeyApiKey = 'api_key';
  static const String prefsKeyProvider = 'ai_provider';
  static const String prefsKeyModel = 'ai_model';
  static const String prefsKeyBaseUrl = 'ai_base_url';
  static const String prefsKeyThemeMode = 'theme_mode';
  static const String prefsKeyOcrEnabled = 'ocr_enabled';
  static const String prefsKeyTextScale = 'text_scale';
  static const String prefsKeyReduceMotion = 'reduce_motion';

  /// Default AI provider. OpenAI-compatible is the most common default.
  static const String defaultProvider = 'openai';

  /// A safe default model for OpenAI-compatible endpoints.
  static const String defaultModel = 'gpt-4o-mini';

  /// The model used for *vision* requests when a separate vision model is
  /// not configured by the user.
  static const String defaultVisionModel = 'gpt-4o-mini';

  /// Default base URL for OpenAI-compatible providers.
  static const String defaultBaseUrl = 'https://api.openai.com/v1';

  /// Official Gemini REST endpoint (model name is appended).
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// OpenRouter endpoint (OpenAI-compatible chat completions).
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// NVIDIA NIM hosted endpoint (OpenAI-compatible chat completions).
  static const String nvidiaBaseUrl = 'https://integrate.api.nvidia.com/v1';

  /// Default vision-capable models per provider, shown as placeholders.
  static const Map<String, String> defaultModelByProvider = {
    'openai': 'gpt-4o-mini',
    'gemini': 'gemini-2.0-flash',
    'openrouter': 'google/gemini-2.0-flash-001',
    'nvidia': 'qwen/qwen2-vl-72b-instruct',
  };

  /// Maximum size in bytes accepted for the image uploaded to the AI API
  /// (we downscale before sending so big phone photos don't blow the budget).
  static const int maxUploadBytes = 4 * 1024 * 1024;

  /// Longest side (px) used when downscaling images for upload.
  static const int maxImageDimension = 1600;

  /// Timeout for a single AI API request.
  static const Duration aiRequestTimeout = Duration(seconds: 60);
}
