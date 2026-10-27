import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/hijriDate.dart';

void main() {
  // Umm al-Qura puts 1 Ramadan 1447 on 18 February 2026.
  final ramadanStart = DateTime(2026, 2, 18);

  group('defaultHijriOffset', () {
    test('is a day behind Makkah in Pakistan, India and Bangladesh', () {
      expect(defaultHijriOffset('PK'), -1);
      expect(defaultHijriOffset('in'), -1);
      expect(defaultHijriOffset('BD'), -1);
    });

    test('follows Makkah elsewhere, or before the country is known', () {
      expect(defaultHijriOffset('SA'), 0);
      expect(defaultHijriOffset('GB'), 0);
      expect(defaultHijriOffset(null), 0);
    });
  });

  group('hijriDateFor', () {
    test('with no adjustment, matches Umm al-Qura', () {
      final h = hijriDateFor(ramadanStart, offsetDays: 0);
      expect([h.hDay, h.hMonth, h.hYear], [1, 9, 1447]);
    });

    test('a day behind shows the previous Hijri date', () {
      final h = hijriDateFor(ramadanStart, offsetDays: -1);
      expect([h.hDay, h.hMonth], [29, 8]); // Sha'ban 1447 has 29 days
    });

    test('moves to the next day at Maghrib', () {
      final maghrib = DateTime(2026, 2, 18, 18, 5);
      final before = hijriDateFor(
        ramadanStart,
        offsetDays: -1,
        maghrib: maghrib,
        now: DateTime(2026, 2, 18, 18, 4),
      );
      final after = hijriDateFor(
        ramadanStart,
        offsetDays: -1,
        maghrib: maghrib,
        now: maghrib,
      );
      expect([before.hDay, before.hMonth], [29, 8]);
      expect([after.hDay, after.hMonth], [1, 9]);
    });

    test('crosses month and year ends', () {
      // 31 Dec 2026 + 2 days lands in January 2027.
      final h = hijriDateFor(DateTime(2026, 12, 31), offsetDays: 2);
      final expected = hijriDateFor(DateTime(2027, 1, 2), offsetDays: 0);
      expect(h.toFormat('dd MM yyyy'), expected.toFormat('dd MM yyyy'));
    });
  });
}
