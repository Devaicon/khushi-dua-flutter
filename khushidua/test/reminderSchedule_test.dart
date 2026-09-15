import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/reminderSchedule.dart';

void main() {
  group('nextOccurrence', () {
    test('returns today when the time is still ahead', () {
      final now = DateTime(2026, 9, 11, 6, 0);
      expect(
        nextOccurrence(hour: 18, minute: 30, now: now),
        DateTime(2026, 9, 11, 18, 30),
      );
    });

    test('rolls to tomorrow when the time has already passed', () {
      final now = DateTime(2026, 9, 11, 19, 0);
      expect(
        nextOccurrence(hour: 18, minute: 30, now: now),
        DateTime(2026, 9, 12, 18, 30),
      );
    });

    test('rolls to tomorrow when the time is exactly now', () {
      final now = DateTime(2026, 9, 11, 6, 30);
      expect(
        nextOccurrence(hour: 6, minute: 30, now: now),
        DateTime(2026, 9, 12, 6, 30),
      );
    });

    test('rolls across a month boundary', () {
      final now = DateTime(2026, 9, 30, 23, 59);
      expect(
        nextOccurrence(hour: 6, minute: 30, now: now),
        DateTime(2026, 10, 1, 6, 30),
      );
    });

    test('rolls across a leap day', () {
      final now = DateTime(2028, 2, 28, 23, 59);
      expect(
        nextOccurrence(hour: 6, minute: 30, now: now),
        DateTime(2028, 2, 29, 6, 30),
      );
    });

    test('drops seconds so the alarm fires on the exact minute', () {
      final now = DateTime(2026, 9, 11, 5, 0, 45);
      final next = nextOccurrence(hour: 6, minute: 30, now: now);
      expect(next.second, 0);
      expect(next.millisecond, 0);
    });
  });

  group('isWithinBannerWindow', () {
    final prayer = DateTime(2026, 9, 11, 13, 0);

    test('true at the prayer time itself', () {
      expect(isWithinBannerWindow(prayer, DateTime(2026, 9, 11, 13, 0)), isTrue);
    });

    test('true just after the prayer time', () {
      expect(
        isWithinBannerWindow(prayer, DateTime(2026, 9, 11, 13, 19)),
        isTrue,
      );
    });

    test('false before the prayer time', () {
      expect(
        isWithinBannerWindow(prayer, DateTime(2026, 9, 11, 12, 59)),
        isFalse,
      );
    });

    test('false once the window has elapsed', () {
      expect(
        isWithinBannerWindow(prayer, DateTime(2026, 9, 11, 13, 21)),
        isFalse,
      );
    });
  });

  group('notificationIdFor', () {
    test('is stable for the same prayer', () {
      expect(notificationIdFor('Fajr'), notificationIdFor('Fajr'));
    });

    test('is distinct across prayers', () {
      final ids = kSchedulablePrayers.map(notificationIdFor).toSet();
      expect(ids.length, kSchedulablePrayers.length);
    });

    test('never collides with the azkar ids', () {
      final ids = kSchedulablePrayers.map(notificationIdFor).toSet();
      expect(ids.contains(kAzkarMorningNotificationId), isFalse);
      expect(ids.contains(kAzkarEveningNotificationId), isFalse);
    });
  });

  group('salahAlertFor', () {
    test('"on" and unknown or missing values play the Salah sound', () {
      expect(salahAlertFor('on'), SalahAlert.sound);
      expect(salahAlertFor(null), SalahAlert.sound);
      expect(salahAlertFor('something-else'), SalahAlert.sound);
    });

    test('"vibrate" stays silent', () {
      expect(salahAlertFor('vibrate'), SalahAlert.vibrate);
    });

    test('"off" schedules nothing', () {
      expect(salahAlertFor('off'), SalahAlert.off);
    });
  });
}
