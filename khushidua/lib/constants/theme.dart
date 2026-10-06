/// The app's single source of visual truth.
///
/// Before this file every screen invented its own padding, radius, shadow and
/// colour, which is what made the app read as a collection of prototypes
/// rather than one product. Nothing outside here should hardcode those values.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

/// Spacing scale. Every gap, padding and margin picks one of these.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. `card` is the default for anything with a surface.
abstract final class AppRadius {
  static const double sm = 12;
  static const double card = 20;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// One shadow, never stacked. Depth comes from the gradient, not from layers
/// of shadow.
abstract final class AppElevation {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Slightly stronger, for surfaces that float over content (the navbar).
  static List<BoxShadow> get raised => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, -2),
    ),
  ];
}

/// Motion durations. Roughly half the app's previous values — the old timings
/// read as sluggish.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
}

/// Text colours for use on top of a gradient card.
abstract final class AppText {
  static const Color onSurface = Colors.white;
  static Color get onSurfaceMuted => Colors.white.withValues(alpha: 0.72);

  /// Text colours for use on the plain page background.
  static Color get onPage => rbluedark;
  static Color get onPageMuted =>
      rbluedark.withValues(alpha: AppPalette.isDark ? 0.62 : 0.55);
}

/// Page backgrounds. A single off-white, not the three different whites the
/// screens used to pick between; a deep navy-black in dark mode.
abstract final class AppSurface {
  static Color get page =>
      AppPalette.isDark ? const Color(0xff0E1120) : const Color(0xffF6F7FB);
  static Color get card =>
      AppPalette.isDark ? const Color(0xff1A1E31) : Colors.white;

  /// A step up from [card], for fields and pressed states on a card.
  static Color get raised =>
      AppPalette.isDark ? const Color(0xff252A40) : const Color(0xffF2F3F8);

  /// Hairline dividers and outlines.
  static Color get line => AppPalette.isDark
      ? Colors.white.withValues(alpha: 0.08)
      : rbluedark.withValues(alpha: 0.06);
}

extension ColorShade on Color {
  /// Darkens by [amount] (0–1) in HSL, clamped so a near-black colour does not
  /// collapse to pure black.
  Color darkenBy(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.08, 1.0))
        .toColor();
  }

  /// Lightens by [amount] (0–1) in HSL.
  Color lightenBy(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 0.95))
        .toColor();
  }

  /// A deep shade of this colour, for text and icons drawn on a light tint
  /// of it. Light seeds such as the pastel blues would be unreadable as-is.
  /// In dark mode the tint sits on a dark card, so the ink turns pale.
  Color get ink {
    final hsl = HSLColor.fromColor(this);
    if (AppPalette.isDark) {
      return hsl.withLightness(hsl.lightness.clamp(0.74, 1.0)).toColor();
    }
    return hsl.withLightness(hsl.lightness.clamp(0.0, 0.36)).toColor();
  }

  /// [ink] as it is on the light theme, for text on a surface that stays
  /// white in both themes.
  Color get inkOnWhite {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(hsl.lightness.clamp(0.0, 0.36)).toColor();
  }

  /// Pulls a colour down until white text sits legibly on it.
  ///
  /// The home palette carries some very light seeds (the yellow and the light
  /// green); left alone they would render white text unreadable. Darkening at
  /// the token level keeps every call site free of special cases.
  Color get seedForWhiteText {
    final hsl = HSLColor.fromColor(this);
    if (hsl.lightness <= 0.62) return this;
    return hsl
        .withLightness(0.55)
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .toColor();
  }
}

/// The card recipe: a solid colour deepening into a darker shade of itself.
///
/// Replaces the old translucent-tint-plus-contrasting-border look, which is
/// what gave cards their unfinished feel.
abstract final class AppGradient {
  static LinearGradient forSeed(Color seed) {
    final base = seed.seedForWhiteText;
    return LinearGradient(
      colors: [base, base.darkenBy(0.14)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// The peach-to-lavender of the sign-in headers; a dusk version of it in
  /// dark mode, where the pastel would glare.
  static LinearGradient get authHeader => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppPalette.isDark
        ? const [Color(0xff4A3440), Color(0xff2B3163)]
        : const [Color(0xffEEB6A3), Color(0xffC3CCF6)],
  );

  /// A neutral surface for unselected states — flat, no border.
  static LinearGradient get neutral => LinearGradient(
    colors: [AppSurface.card, AppSurface.raised],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// The home screen's category tiles, by age group
/// (0 little kids, 1 older kids, 2 grown ups).
///
/// Little kids get solid, softly graded tiles with white text. Older kids and
/// grown ups share a quieter look: a light fill of the colour, a stronger
/// border of it, and dark text.
abstract final class CategoryPalette {
  static bool isVivid(int ageGroup) => ageGroup == 0;

  static BoxDecoration tileDecoration(Color seed, int ageGroup) {
    if (isVivid(ageGroup)) {
      final base = seed.seedForWhiteText.lightenBy(0.03);
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [base, base.darkenBy(0.09)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardAll,
        boxShadow: AppElevation.card,
      );
    }
    return BoxDecoration(
      color: seed.withValues(alpha: AppPalette.isDark ? 0.18 : 0.3),
      borderRadius: AppRadius.cardAll,
      border: Border.all(
        color: seed.withValues(alpha: AppPalette.isDark ? 0.45 : 0.5),
        width: 1.5,
      ),
    );
  }

  /// Label and fallback-icon colour for a tile.
  static Color contentColor(int ageGroup) =>
      isVivid(ageGroup) ? AppText.onSurface : rtext;
}

/// The one decoration every card in the app uses.
BoxDecoration cardDecoration(Color seed, {double? radius}) => BoxDecoration(
  gradient: AppGradient.forSeed(seed),
  borderRadius: BorderRadius.circular(radius ?? AppRadius.card),
  boxShadow: AppElevation.card,
);

/// A plain white card, for lists where a coloured card would be noise.
BoxDecoration plainCardDecoration({double? radius}) => BoxDecoration(
  color: AppSurface.card,
  borderRadius: BorderRadius.circular(radius ?? AppRadius.card),
  // Shadows barely show on a dark page, so a hairline edges the card there.
  border: AppPalette.isDark
      ? Border.all(color: Colors.white.withValues(alpha: 0.05))
      : null,
  boxShadow: AppElevation.card,
);

/// Transparent system bars with icons that suit the page: dark on the light
/// theme, light on the dark one. Before this, a phone in dark mode drew light
/// icons on the light pages — unreadable.
SystemUiOverlayStyle get kAppOverlayStyle => SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: AppPalette.isDark
      ? Brightness.light
      : Brightness.dark,
  statusBarBrightness: AppPalette.isDark ? Brightness.dark : Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: AppPalette.isDark
      ? Brightness.light
      : Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Material's own surfaces — dialogs, switches, app bars, fields — read from
/// this, so they stop looking like they belong to a different app.
ThemeData buildAppTheme() {
  final bool dark = AppPalette.isDark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: kBrandNavy,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: dark ? const Color(0xFF9FA8DA) : kBrandNavy,
        onPrimary: dark ? kBrandNavy : Colors.white,
        surface: AppSurface.card,
        onSurface: rtext,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppSurface.page,
    canvasColor: AppSurface.card,
    cardColor: AppSurface.card,
    dividerColor: AppSurface.line,
    splashFactory: InkRipple.splashFactory,
    fontFamily: null,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: kAppOverlayStyle,
      backgroundColor: AppSurface.page,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: rbluedark),
      titleTextStyle: TextStyle(
        color: rbluedark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppSurface.card,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: rbluedark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: rtext, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppSurface.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppSurface.card,
      surfaceTintColor: Colors.transparent,
    ),
    // White thumb in both states; only the track carries the colour. Any
    // activeColor set on a switch overrides this and paints the thumb too.
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? (dark ? const Color(0xFF5C6BC0) : kBrandNavy)
            : (dark ? const Color(0xFF3A3F57) : Colors.grey.shade400),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? rbluedark
            : rbluedark.withValues(alpha: 0.4),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kBrandNavy : null,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: rbluedark),
    iconTheme: IconThemeData(color: rbluedark),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppSurface.card,
      hintStyle: TextStyle(color: AppText.onPageMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.cardAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.cardAll,
        borderSide: BorderSide.none,
      ),
      // The one place a border still earns its keep: showing focus.
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.cardAll,
        borderSide: BorderSide(color: rbluedark, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: rbluedark,
      selectionHandleColor: rbluedark,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: rbluedark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
