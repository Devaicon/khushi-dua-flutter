import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Fonts for Arabic-script content. The families are declared in
/// pubspec.yaml and match the mobile app's: all Arabic text uses
/// Noor-e-Huda and all Urdu text uses Jameel Noori Nastaleeq, so what is
/// typed and previewed here looks like what readers see.
abstract final class AppFonts {
  static const String arabic = 'arabic';
  static const String urdu = 'urdu';

  /// Noto Naskh Arabic, for the few characters [arabic] and [urdu] lack
  /// (digits, alef wasla, tatweel in Urdu), and for Arabic-script
  /// text in any other language, so none of it comes from the browser.
  static const String naskh = 'naskh';
  static const List<String> fallback = [naskh];

  /// Smallest line height, as a multiple of font size, that keeps a line's
  /// tallest marks and deepest tails off the lines around it: Nastaleeq
  /// stacks rise 1.22em over a 0.96em ascent, and Noor-e-Huda's harakat
  /// reach 1.37em above and 0.6em below.
  static const double urduMinHeight = 1.8;
  static const double arabicMinHeight = 2.0;

  /// The family for content in the Firestore language [field] ('arabic',
  /// 'urdu', ...), or null for the default font.
  static String? forField(String field) => switch (field) {
    'arabic' => arabic,
    'urdu' => urdu,
    _ => null,
  };

  /// The font for content in [field], with [height] raised to what it
  /// needs; null for languages that use the default font, so it can be
  /// passed straight to `style:` or `merge`.
  static TextStyle? styleFor(String field, {double? height}) {
    final family = forField(field);
    if (family == null) return null;
    final min = family == urdu ? urduMinHeight : arabicMinHeight;
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      height: math.max(height ?? 0, min),
    );
  }
}
