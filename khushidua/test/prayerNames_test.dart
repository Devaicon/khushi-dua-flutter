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
      // Heh is U+06C1: the bundled font has no glyph for U+0647.
      expect(arabicPrayerName("Dhuhr"), "الظہر");
      expect(arabicPrayerName("Asr"), "العصر");
      expect(arabicPrayerName("Maghrib"), "المغرب");
      expect(arabicPrayerName("Ishaa"), "العشاء");
    });

    test('uses only letters the bundled Arabic font can draw', () {
      // Noor-e-Hidaya has no glyph for these; each falls back to a system
      // font and breaks the joining of the word around it.
      const unsupported = {0x0647: 'heh', 0x0629: 'teh marbuta', 0x064A: 'yeh'};
      for (final entry in kArabicPrayerNames.entries) {
        for (final rune in entry.value.runes) {
          expect(
            unsupported.containsKey(rune),
            isFalse,
            reason: '${entry.key} uses ${unsupported[rune]} (U+'
                '${rune.toRadixString(16).toUpperCase()})',
          );
        }
      }
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
