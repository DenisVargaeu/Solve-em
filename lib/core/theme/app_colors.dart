library;

import 'package:flutter/material.dart';

/// Brand palette for Solve 'em.
///
/// A calm violet/indigo seed that reads "intelligent, trustworthy, focused" —
/// similar in spirit to Google Lens / Photomath. Each surface color is
/// derived from the seed inside [buildColorScheme] so light/dark stay
/// consistent.

abstract final class AppColors {
  AppColors._();

  /// Primary seed color for the Material 3 scheme.
  static const Color seed = Color(0xFF5B5BEF);

  /// Deep violet used for the "AI Mode" gradient card.
  static const Color aiViolet = Color(0xFF7C4DFF);

  /// Teal used for the "Control Mode" gradient card.
  static const Color controlTeal = Color(0xFF00BFA5);

  /// Amber used for the "No AI Mode" gradient card.
  static const Color noAiAmber = Color(0xFFFFB300);

  /// Pink used for the "Chat" gradient card.
  static const Color chatPink = Color(0xFFEC407A);

  /// Companion colors for gradient cards.
  static const Color aiVioletLight = Color(0xFFB388FF);
  static const Color controlTealLight = Color(0xFF64FFDA);
  static const Color noAiAmberLight = Color(0xFFFFE082);
  static const Color chatPinkLight = Color(0xFFFF80AB);

  /// Success green.
  static const Color success = Color(0xFF2E7D32);

  /// Error red.
  static const Color danger = Color(0xFFC62828);
}
