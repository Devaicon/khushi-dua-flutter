import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/nextPrayer.dart';

void main() {
  final day = DateTime(2026, 10, 6);
  DateTime at(int h, int m) => day.add(Duration(hours: h, minutes: m));
  final today = {
    'Fajr': at(4, 50),
    'Sunrise': at(6, 10),
    'Dhuhr': at(12, 3),
    'Asr': at(15, 22),
    'Maghrib': at(17, 53),
    'Ishaa': at(19, 13),
  };
  final tomorrowFajr = DateTime(2026, 10, 7, 4, 51);

  test('picks the first prayer still ahead', () {
    final next = nextPrayerAfter(
      now: at(13, 0),
      today: today,
      tomorrowFajr: tomorrowFajr,
    );
    expect(next?.name, 'Asr');
    expect(next?.time, at(15, 22));
  });

  test('before Fajr, Fajr today is next', () {
    expect(
      nextPrayerAfter(now: at(1, 0), today: today, tomorrowFajr: tomorrowFajr)
          ?.name,
      'Fajr',
    );
  });

  test('after Isha, rolls over to tomorrow\'s Fajr', () {
    final next = nextPrayerAfter(
      now: at(22, 0),
      today: today,
      tomorrowFajr: tomorrowFajr,
    );
    expect(next?.name, 'Fajr');
    expect(next?.time, tomorrowFajr);
  });

  test('a prayer starting exactly now is no longer next', () {
    expect(
      nextPrayerAfter(
        now: at(15, 22),
        today: today,
        tomorrowFajr: tomorrowFajr,
      )?.name,
      'Maghrib',
    );
  });

  test('skips times that could not be calculated', () {
    expect(
      nextPrayerAfter(
        now: at(13, 0),
        today: {...today, 'Asr': null},
        tomorrowFajr: tomorrowFajr,
      )?.name,
      'Maghrib',
    );
  });

  test('null when nothing is ahead and tomorrow is unknown', () {
    expect(nextPrayerAfter(now: at(22, 0), today: today), isNull);
  });
}
