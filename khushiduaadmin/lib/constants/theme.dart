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

/// The colour tokens. They read [isDark] directly, as the app's do, so a
/// widget needs no context to pick a colour; flipping it and rebuilding the
/// app switches every screen (see AppearanceController).
abstract final class Palette {
  static bool isDark = false;

  /// The brand as ink: text, icons and the tints made from them. Navy on
  /// light pages; a pale indigo on dark ones, where navy would vanish.
  static Color get brand =>
      isDark ? const Color(0xFFC5CAE9) : const Color(0xFF1A237E);

  /// The brand as a fill behind white text: buttons, switches. Navy is too
  /// close to the dark page, so it brightens to indigo there.
  static Color get brandFill =>
      isDark ? const Color(0xFF3F51B5) : const Color(0xFF1A237E);

  /// Selected rows and soft highlights.
  static Color get brandSoft =>
      isDark ? const Color(0xFF283062) : const Color(0xFFE8EAF6);

  static Color get page =>
      isDark ? const Color(0xff0E1120) : const Color(0xffF6F7FB);
  static Color get card => isDark ? const Color(0xff1A1E31) : Colors.white;

  /// A step up from [card], for fields and hovered rows.
  static Color get raised =>
      isDark ? const Color(0xff252A40) : const Color(0xffF2F3F8);
  static Color get line =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x141A237E);

  static Color get text =>
      isDark ? const Color(0xffE6E8F2) : const Color(0xff2D3142);
  static Color get textMuted =>
      isDark ? const Color(0xff9EA3BC) : const Color(0xff7A7F95);

  static Color get success =>
      isDark ? const Color(0xff81C784) : const Color(0xff2E7D32);
  static Color get warning =>
      isDark ? const Color(0xffFFB74D) : const Color(0xffB26A00);
  static Color get danger =>
      isDark ? const Color(0xffEF9A9A) : const Color(0xffC62828);
  static Color get info =>
      isDark ? const Color(0xff90CAF9) : const Color(0xff1565C0);

  /// The age groups, coloured as the app's home screen buttons.
  static const Color littleKids = Color(0xFFF48FB1);
  static const Color olderKids = Color(0xFF90CAF9);
  static const Color grownUps = Color(0xFFA5D6A7);

  /// The sign-in gradient: peach to lavender, or the app's dusk version.
  static List<Color> get authGradient => isDark
      ? [const Color(0xff4A3440), const Color(0xff2B3163)]
      : [const Color(0xffEEB6A3), const Color(0xffC3CCF6)];
}

/// One shadow, never stacked; deeper on the dark page, where a light one
/// would not show.
abstract final class Elevation {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: Palette.isDark ? 0.3 : 0.06),
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

/// A shade of [color] for text and icons on a tint of it: deep on light
/// pages, pale on dark ones, as the app's `ink`.
Color inkOf(Color color) {
  final hsl = HSLColor.fromColor(color);
  if (Palette.isDark) {
    return hsl.withLightness(hsl.lightness.clamp(0.74, 1.0)).toColor();
  }
  return hsl.withLightness(hsl.lightness.clamp(0.0, 0.36)).toColor();
}

ThemeData buildAdminTheme() {
  final dark = Palette.isDark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A237E),
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: dark ? const Color(0xFF9FA8DA) : Palette.brandFill,
    onPrimary: dark ? const Color(0xFF1A237E) : Colors.white,
    surface: Palette.card,
    onSurface: Palette.text,
    error: Palette.danger,
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: Radii.smAll,
    borderSide: BorderSide(color: Palette.line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.page,
    canvasColor: Palette.card,
    cardColor: Palette.card,
    dividerColor: Palette.line,
    dividerTheme: DividerThemeData(color: Palette.line, space: 1),
    textTheme: (dark ? Typography.whiteMountainView : Typography.blackMountainView).apply(
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
    iconTheme: IconThemeData(color: Palette.brand),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.cardAll),
      titleTextStyle: TextStyle(
        color: Palette.brand,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: Palette.text, fontSize: 14),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
    ),
    // Chips and segmented buttons read these; on the dark page Material's
    // defaults would be light grey.
    chipTheme: ChipThemeData(
      backgroundColor: Palette.card,
      selectedColor: Palette.brandSoft,
      side: BorderSide(color: Palette.line),
      labelStyle: TextStyle(color: Palette.text),
    ),
    // White thumb in both states, as in the app; only the track is coloured.
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Palette.brandFill
            : (dark ? const Color(0xFF3A3F57) : Colors.grey.shade400),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.brandFill : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: Palette.brand),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: dark ? const Color(0xff3A3F57) : const Color(0xff2D3142),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.card,
      isDense: true,
      hintStyle: TextStyle(color: Palette.textMuted),
      labelStyle: TextStyle(color: Palette.textMuted),
      floatingLabelStyle: TextStyle(color: Palette.brand),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md + 2,
      ),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: BorderSide(color: Palette.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: BorderSide(color: Palette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Radii.smAll,
        borderSide: BorderSide(color: Palette.danger, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: Palette.brand),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.brand,
        shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Palette.brand,
      unselectedLabelColor: Palette.textMuted,
      indicatorColor: Palette.brand,
      dividerColor: Palette.line,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(Palette.brand.withValues(alpha: 0.25)),
      radius: const Radius.circular(8),
    ),
  );
}
