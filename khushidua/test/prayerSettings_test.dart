import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/controllers/prayerSettingsController.dart';

void main() {
  test('offers exactly the six requested calculation methods', () {
    expect(PrayerSettingsController.methods.values, [
      'Egyptian General Authority of Survey',
      'University of Islamic Sciences, Karachi',
      'Umm al-Qura University, Makkah',
      'Islamic Society of North America',
      'Muslim World League',
      'Presidency of Religious Affairs, Turkey',
    ]);
  });

  test('keeps a stored method that is still offered', () {
    expect(PrayerSettingsController.normaliseMethod('turkey'), 'turkey');
  });

  test('a method no longer offered, or none, falls back to Karachi', () {
    expect(PrayerSettingsController.normaliseMethod('singapore'), 'karachi');
    expect(PrayerSettingsController.normaliseMethod(null), 'karachi');
  });
}
