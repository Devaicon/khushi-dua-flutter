import 'package:flutter/material.dart';

/// Which palette the colour tokens resolve to. Set by AppearanceController;
/// read by every token that differs between light and dark.
abstract final class AppPalette {
  static bool isDark = false;
}

const Color rwhite = Color(0xffffffff);
const Color rblack = Color(0xff000000);
const Color rpink = Color(0xFFF48FB1); // More vibrant pink
const Color rhint = Color(0xffB3B4B9);

/// Body text on the page.
Color get rtext => AppPalette.isDark ? const Color(0xffE6E8F2) : kTextDark;
const Color kTextDark = Color(0xff2D3142);
const Color rlightPink = Color(0xFFFFD1DE);
const Color rpurple = Color(0xFF9FA8DA); // More vibrant purple
const Color rblue = Color(0xFF90CAF9); // More vibrant blue
const Color rgreen = Color(0xFFA5D6A7); // More vibrant green
const Color rpurpleShade = Color(0xFFC5CAE9);
const Color rblueshade = Color(0xFF81D4FA);
const Color ryellow = Color(0xFFFFF59D); // More vibrant yellow
/// The brand navy, for fills: cards, buttons, selected states. It stays navy
/// in dark mode, where it still carries white text.
const Color kBrandNavy = Color(0xFF1A237E);

/// Navy for small filled controls — buttons, selected pills, badges. On a
/// dark page navy is too close to the background, so it brightens to indigo.
Color get brandFill => AppPalette.isDark ? const Color(0xFF3F51B5) : kBrandNavy;

/// The brand colour as ink: text and icons on the page, and the tints made
/// from it. Navy on light pages; a pale indigo on dark ones, where navy text
/// would vanish.
Color get rbluedark => AppPalette.isDark ? const Color(0xFFC5CAE9) : kBrandNavy;

// Premium Accent Colors
const Color rAccentGold = Color(0xFFFFD700);
const Color rAccentDeepPurple = Color(0xFF4A148C);
const Color rAccentTeal = Color(0xFF006064);

// Premium Gradients
const LinearGradient rGoldGradient = LinearGradient(
  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient rPremiumBlueGradient = LinearGradient(
  colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient rDeepSpiritGradient = LinearGradient(
  colors: [Color(0xFF2A158F), Color(0xFF4A148C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
