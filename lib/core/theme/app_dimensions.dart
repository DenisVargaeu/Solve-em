library;

import 'package:flutter/widgets.dart';

/// Material 3 design tokens: spacing scale + component shape radii.
///
/// Centralizing these keeps every screen consistent with the M3 spec
/// (8dp spacing baseline, 4/8/12/16/28 shape scale) instead of hard-coding
/// ad-hoc numbers.

abstract final class AppSpace {
  AppSpace._();

  /// 4dp — tightest gap between inline/related elements.
  static const double xs = 4;

  /// 8dp — secondary micro-gaps.
  static const double sm = 8;

  /// 12dp — standard gap between related controls.
  static const double md = 12;

  /// 16dp — card padding & gap between card groups.
  static const double lg = 16;

  /// 20dp — comfortable card inner padding.
  static const double xl = 20;

  /// 24dp — section spacing and large card padding.
  static const double xxl = 24;

  /// 32dp — screen-edge breathing room between major blocks.
  static const double xxxl = 32;

  /// Standard lateral screen padding with SafeArea.
  static const EdgeInsets screen =
      EdgeInsets.fromLTRB(xl, sm, xl, xxl);

  /// Standard inner padding for tonally raised cards.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// M3 shape scale (corner radii in dp).
abstract final class AppRadii {
  AppRadii._();

  /// M3 small shapes — chips, input fields.
  static const double sm = 8;

  /// M3 medium shapes — compact cards, tiles.
  static const double md = 12;

  /// M3 large shapes — buttons, search/field containers, dialogs.
  static const double lg = 16;

  /// M3 extra-large shapes — hero/bottom-sheet surfaces.
  static const double xl = 28;

  /// Fully rounded pill.
  static const double pill = 999;

  static BorderRadius radius(double r) => BorderRadius.circular(r);
}