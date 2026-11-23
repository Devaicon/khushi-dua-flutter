import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Fonts for Arabic-script text. The families are declared in pubspec.yaml.
///
/// All Arabic text uses Noor-e-Huda ([arabic]) and all Urdu text uses
/// Jameel Noori Nastaleeq ([urdu]). The whole interface switches to one of
/// them when the app language is Arabic or Urdu (see buildAppTheme), and
/// text that is Arabic whatever the language, like a dua, names [arabic]
/// itself.
abstract final class AppFonts {
  static const String arabic = 'arabic';
  static const String urdu = 'urdu';

  /// Noto Naskh Arabic, for the few characters [arabic] and [urdu] lack
  /// (digits, alef wasla, tatweel in Urdu), so they never come from
  /// whatever font the device happens to have.
  static const String naskh = 'naskh';
  static const List<String> fallback = [naskh];

  /// Smallest line height, as a multiple of font size, that keeps a line's
  /// tallest marks and deepest tails off the lines around it. Measured on
  /// the app's own strings: Nastaleeq stacks rise 1.22em over a 0.96em
  /// ascent, so the font's natural 1.4 lines collide; Noor-e-Huda's
  /// harakat reach 1.37em above and 0.6em below.
  static const double urduMinHeight = 1.8;
  static const double arabicMinHeight = 2.0;

  /// The family for text in [language] (a name such as 'Urdu', as stored in
  /// UserController.selectedLanguage), or null for the default font.
  static String? forLanguage(String? language) => switch (language) {
    'Urdu' => urdu,
    'Arabic' => arabic,
    _ => null,
  };

  /// The family for the app's current language, or null for the default.
  static String? get current => forLanguage(Get.locale?.languageCode);

  static double? minHeightOf(String? family) => switch (family) {
    urdu => urduMinHeight,
    arabic => arabicMinHeight,
    _ => null,
  };

  /// [height] raised to what [family] (default: the current language's
  /// font) needs, for text styles that set their own line height.
  static double? height(double? height, {String? family}) {
    final min = minHeightOf(family ?? current);
    if (min == null) return height;
    return math.max(height ?? 0, min);
  }

  /// [theme] with every style's line height raised to what [family] needs.
  static TextTheme raiseHeights(TextTheme theme, String family) {
    TextStyle? raise(TextStyle? s) =>
        s?.copyWith(height: height(s.height, family: family));
    return theme.copyWith(
      displayLarge: raise(theme.displayLarge),
      displayMedium: raise(theme.displayMedium),
      displaySmall: raise(theme.displaySmall),
      headlineLarge: raise(theme.headlineLarge),
      headlineMedium: raise(theme.headlineMedium),
      headlineSmall: raise(theme.headlineSmall),
      titleLarge: raise(theme.titleLarge),
      titleMedium: raise(theme.titleMedium),
      titleSmall: raise(theme.titleSmall),
      bodyLarge: raise(theme.bodyLarge),
      bodyMedium: raise(theme.bodyMedium),
      bodySmall: raise(theme.bodySmall),
      labelLarge: raise(theme.labelLarge),
      labelMedium: raise(theme.labelMedium),
      labelSmall: raise(theme.labelSmall),
    );
  }
}
