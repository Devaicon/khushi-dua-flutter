/// The admin panel's visual system, matched to the mobile app's
/// (khushidua/lib/constants/theme.dart): the same navy brand, off-white page,
/// white cards, spacing scale and radii, so what an admin edits here looks
/// like what readers see.
///
/// Nothing outside this file should hardcode a colour, radius or shadow.
library;

import 'package:flutter/material.dart';

/// Spacing scale, as in the app.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii, as in the app.
abstract final class Radii {
  static const double sm = 12;
  static const double card = 20;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

abstract final class Palette {
  /// The app's brand navy.
  static const Color brand = Color(0xFF1A237E);
  static const Color brandSoft = Color(0xFFE8EAF6);

  static const Color page = Color(0xffF6F7FB);
  static const Color card = Colors.white;

  /// A step up from [card], for fields and hovered rows.
  static const Color raised = Color(0xffF2F3F8);
  static const Color line = Color(0x141A237E);

  static const Color text = Color(0xff2D3142);
  static const Color textMuted = Color(0xff7A7F95);

  static const Color success = Color(0xff2E7D32);
  static const Color warning = Color(0xffB26A00);
  static const Color danger = Color(0xffC62828);
  static const Color info = Color(0xff1565C0);

  /// The age groups, coloured as the app's home screen buttons.
  static const Color littleKids = Color(0xFFF48FB1);
  static const Color olderKids = Color(0xFF90CAF9);
  static const Color grownUps = Color(0xFFA5D6A7);
}

/// One shadow, never stacked.
abstract final class Elevation {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;
}

/// A deep shade of [color], for text and icons on a light tint of it.
Color inkOf(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness(hsl.lightness.clamp(0.0, 0.36)).toColor();
}

ThemeData buildAdminTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Palette.brand).copyWith(
    primary: Palette.brand,
    onPrimary: Colors.white,
    surface: Palette.card,
    onSurface: Palette.text,
    error: Palette.danger,
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: Radii.smAll,
    borderSide: const BorderSide(color: Palette.line),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.page,
    canvasColor: Palette.card,
    cardColor: Palette.card,
    dividerColor: Palette.line,
    dividerTheme: const DividerThemeData(color: Palette.line, space: 1),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
    iconTheme: const IconThemeData(color: Palette.brand),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.cardAll),
      titleTextStyle: const TextStyle(
        color: Palette.brand,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: Palette.text, fontSize: 14),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
    ),
    // White thumb in both states, as in the app; only the track is coloured.
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Palette.brand
            : Colors.grey.shade400,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.brand : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Palette.brand),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.text,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.card,
      isDense: true,
      hintStyle: const TextStyle(color: Palette.textMuted),
      labelStyle: const TextStyle(color: Palette.textMuted),
      floatingLabelStyle: const TextStyle(color: Palette.brand),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md + 2,
      ),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: const BorderSide(color: Palette.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: const BorderSide(color: Palette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: const BorderSide(color: Palette.danger, width: 1.5),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.brand,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.brand,
        shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Palette.brand,
      unselectedLabelColor: Palette.textMuted,
      indicatorColor: Palette.brand,
      dividerColor: Palette.line,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(Palette.brand.withValues(alpha: 0.25)),
      radius: const Radius.circular(8),
    ),
  );
}
