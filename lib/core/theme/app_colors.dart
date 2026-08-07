library;

import 'package:flutter/material.dart';

/// Brand palette for Solve 'em.
///
/// A calm green seed that reads "fresh, focused, trustworthy" — growth and
/// clarity, similar in spirit to math/study apps. Each surface color is
/// derived from the seed inside [buildColorScheme] so light/dark stay
/// consistent.

abstract final class AppColors {
  AppColors._();

  /// Primary seed color for the Material 3 scheme.
  static const Color seed = Color(0xFF16A34A);

  /// Deep green used for the "AI Mode" gradient card.
  static const Color aiViolet = Color(0xFF22C55E);

  /// Teal-green used for the "Control Mode" gradient card.
  static const Color controlTeal = Color(0xFF14B8A6);

  /// Lime used for the "No AI Mode" gradient card.
  static const Color noAiAmber = Color(0xFF84CC16);

  /// Emerald used for the "Chat" gradient card.
  static const Color chatPink = Color(0xFF10B981);

  /// Companion colors for gradient cards.
  static const Color aiVioletLight = Color(0xFF86EFAC);
  static const Color controlTealLight = Color(0xFF5EEAD4);
  static const Color noAiAmberLight = Color(0xFFD9F99D);
  static const Color chatPinkLight = Color(0xFF6EE7B7);

  /// Success green.
  static const Color success = Color(0xFF2E7D32);

  /// Error red.
  static const Color danger = Color(0xFFC62828);
}
