/// Arabic names for the rows shown on the prayer times screen.
///
/// Keys are the internal English names built in `views/subScreens/prayer.dart`
/// — note "Ishaa", which is spelled that way throughout the app.
const Map<String, String> kArabicPrayerNames = {
  "Fajr": "الفجر",
  "Sunrise": "الشروق",
  "Dhuhr": "الظهر",
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
