import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/constants/prayerNames.dart';

void main() {
  group('arabicPrayerName', () {
    test('covers every row the prayer screen builds', () {
      const rowsBuiltByPrayerScreen = [
        "Fajr",
        "Sunrise",
        "Dhuhr",
        "Asr",
        "Maghrib",
        "Sunset",
        "Ishaa",
      ];
      for (final name in rowsBuiltByPrayerScreen) {
        expect(
          arabicPrayerName(name),
          isNotEmpty,
          reason: '$name has no Arabic name',
        );
      }
    });

    test('returns the expected Arabic for the five prayers', () {
      expect(arabicPrayerName("Fajr"), "الفجر");
      expect(arabicPrayerName("Dhuhr"), "الظهر");
      expect(arabicPrayerName("Asr"), "العصر");
      expect(arabicPrayerName("Maghrib"), "المغرب");
      expect(arabicPrayerName("Ishaa"), "العشاء");
    });

    test('distinguishes sunrise from sunset', () {
      expect(arabicPrayerName("Sunrise"), "الشروق");
      expect(arabicPrayerName("Sunset"), "الغروب");
      expect(
        arabicPrayerName("Sunrise"),
        isNot(arabicPrayerName("Sunset")),
      );
    });

    test('returns empty for an unknown name rather than throwing', () {
      expect(arabicPrayerName("Tahajjud"), isEmpty);
    });
  });
}
