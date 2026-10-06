/// Arabic names for the rows shown on the prayer times screen.
///
/// Drawn in the bundled `arabic` font (Noor-e-Hidaya), an Indo-Pak font that
/// has no glyph for the Arabic heh U+0647; it draws heh only as U+06C1. A
/// U+0647 fell back to a system font and could not join the letters around
/// it, so «الظهر» rendered with a detached heh. Dhuhr therefore uses U+06C1.
///
/// Keys are the internal English names built in `views/subScreens/prayer.dart`
/// — note "Ishaa", which is spelled that way throughout the app.
const Map<String, String> kArabicPrayerNames = {
  "Fajr": "الفجر",
  "Sunrise": "الشروق",
  "Dhuhr": "الظہر",
  "Asr": "العصر",
  "Maghrib": "المغرب",
  "Sunset": "الغروب",
  "Ishaa": "العشاء",
};

/// The Arabic name for a prayer, or an empty string when there isn't one.
///
/// Callers render this beside the English name, so an empty result simply
/// means nothing extra is drawn.
String arabicPrayerName(String name) => kArabicPrayerNames[name] ?? '';
