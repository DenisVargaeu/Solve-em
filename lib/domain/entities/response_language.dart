library;

/// Languages the AI can respond in.
///
/// The model is asked to write all explanation text (steps, hints, feedback,
/// chat replies) in the selected language. More languages will be added over
/// time.

enum ResponseLanguage {
  english('en', 'English', 'English'),
  slovak('sk', 'Slovak', 'Slovenčina'),
  czech('cs', 'Czech', 'Čeština'),
  german('de', 'German', 'Deutsch'),
  spanish('es', 'Spanish', 'Español'),
  french('fr', 'French', 'Français'),
  italian('it', 'Italian', 'Italiano'),
  portuguese('pt', 'Portuguese', 'Português'),
  polish('pl', 'Polish', 'Polski'),
  hungarian('hu', 'Hungarian', 'Magyar');

  const ResponseLanguage(this.code, this.label, this.nativeName);

  /// Short ISO-like code used for persistence and as a prompt hint.
  final String code;

  /// English label shown in the picker.
  final String label;

  /// The language its own speakers call it.
  final String nativeName;

  /// The name to show in the UI options.
  String get displayName => nativeName;

  /// Resolves a persisted code back to an enum, falling back to English.
  static ResponseLanguage fromCode(String? code) =>
      ResponseLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => ResponseLanguage.english,
      );
}