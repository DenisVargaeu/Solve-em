library;

/// The AI provider the user has configured.

enum AiProvider {
  /// Any OpenAI-compatible `/chat/completions` endpoint (default: OpenAI).
  openai('openai', 'OpenAI Compatible'),

  /// Google Gemini `generateContent` endpoint.
  gemini('gemini', 'Google Gemini'),

  /// OpenRouter (OpenAI-compatible proxy to many models).
  openrouter('openrouter', 'OpenRouter'),

  /// NVIDIA NIM hosted models (OpenAI-compatible endpoint).
  nvidia('nvidia', 'NVIDIA NIM');

  const AiProvider(this.id, this.label);

  /// Stable storage id.
  final String id;

  /// Human readable label.
  final String label;

  /// Looks up a provider by its storage [id]; defaults to [openai].
  static AiProvider fromId(String? id) => AiProvider.values.firstWhere(
    (p) => p.id == id,
    orElse: () => AiProvider.openai,
  );
}

/// The mode a solved problem was produced in.
enum SolveMode {
  /// Photo of a problem → AI generates the full solution.
  ai('ai', 'AI Mode'),

  /// Photo of the user's own work → AI checks it.
  control('control', 'Control Mode'),

  /// Offline, no AI involved.
  noAi('noai', 'No AI Mode');

  const SolveMode(this.id, this.label);

  final String id;
  final String label;

  static SolveMode fromId(String? id) => SolveMode.values.firstWhere(
    (m) => m.id == id,
    orElse: () => SolveMode.ai,
  );
}
