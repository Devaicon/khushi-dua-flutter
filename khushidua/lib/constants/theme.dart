/// The app's single source of visual truth.
///
/// Before this file every screen invented its own padding, radius, shadow and
/// colour, which is what made the app read as a collection of prototypes
/// rather than one product. Nothing outside here should hardcode those values.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

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
  static const Color onPage = rbluedark;
  static Color get onPageMuted => rbluedark.withValues(alpha: 0.55);
}

/// Page backgrounds. A single off-white, not the three different whites the
/// screens used to pick between.
abstract final class AppSurface {
  static const Color page = Color(0xffF6F7FB);
  static const Color card = Colors.white;
}

extension ColorShade on Color {
  /// Darkens by [amount] (0–1) in HSL, clamped so a near-black colour does not
  /// collapse to pure black.
  Color darkenBy(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.08, 1.0)).toColor();
  }

  /// Lightens by [amount] (0–1) in HSL.
  Color lightenBy(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 0.95)).toColor();
  }

  /// Pulls a colour down until white text sits legibly on it.
  ///
  /// The home palette carries some very light seeds (the yellow and the light
  /// green); left alone they would render white text unreadable. Darkening at
  /// the token level keeps every call site free of special cases.
  Color get seedForWhiteText {
    final hsl = HSLColor.fromColor(this);
    if (hsl.lightness <= 0.62) return this;
    return hsl.withLightness(0.55).withSaturation(
      (hsl.saturation * 1.1).clamp(0.0, 1.0),
    ).toColor();
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

  /// A neutral surface for unselected states — flat, no border.
  static const LinearGradient neutral = LinearGradient(
    colors: [Colors.white, Color(0xffF2F3F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
  boxShadow: AppElevation.card,
);

/// Material's own surfaces — dialogs, switches, app bars, fields — read from
/// this, so they stop looking like they belong to a different app.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: rbluedark,
    primary: rbluedark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppSurface.page,
    splashFactory: InkRipple.splashFactory,
    fontFamily: null,
    appBarTheme: const AppBarTheme(
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? rbluedark
            : Colors.grey.shade400,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: rbluedark, width: 1.5),
      ),
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
