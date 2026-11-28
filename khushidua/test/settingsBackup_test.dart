import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/constants/theme.dart';
import 'package:khushidua/services/settingsBackup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('settings backup', () {
    test('round-trips every preference type', () {
      final values = <String, Object>{
        'profileName': 'Aisha',
        'listenedDuas': ['a', 'b'],
        'selectedAgeGroup': 2,
        'azkarReminderEnabled': true,
      };
      expect(SettingsBackup.decode(SettingsBackup.encode(values)), values);
    });

    test('rejects a file that is not ours', () {
      expect(
        () => SettingsBackup.decode('{"hello": "world"}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => SettingsBackup.decode('not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('says so when the file comes from a newer app', () {
      final source =
          '{"app": "khushidua", "format": ${SettingsBackup.formatVersion + 1}, "settings": {}}';
      expect(
        () => SettingsBackup.decode(source),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.newerVersion,
            'newerVersion',
            isTrue,
          ),
        ),
      );
    });

    test('ignores keys that are not portable and values of the wrong type', () {
      const source = '''
{
  "app": "khushidua",
  "format": 1,
  "settings": {
    "profileName": {"type": "string", "value": "Bilal"},
    "contentCacheVersion": {"type": "int", "value": 9},
    "selectedAgeGroup": {"type": "int", "value": "two"}
  }
}''';
      expect(SettingsBackup.decode(source), {'profileName': 'Bilal'});
    });

    test('export leaves device-only state behind', () async {
      SharedPreferences.setMockInitialValues({
        'profileName': 'Aisha',
        'tipSeen.listened': true,
        'lastKnownPrayerTimes': ['Fajr|300'],
        'contentCacheVersion': 4,
      });
      final values = SettingsBackup.decode(await SettingsBackup.export());
      expect(values.keys, unorderedEquals(['profileName', 'tipSeen.listened']));
    });

    test('apply replaces portable settings and keeps the rest', () async {
      SharedPreferences.setMockInitialValues({
        'profileName': 'Old',
        'azkarReminderEnabled': true,
        'contentCacheVersion': 4,
      });
      await SettingsBackup.apply({'profileName': 'New'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profileName'), 'New');
      // Not in the backup, so it is cleared rather than left mixed in.
      expect(prefs.containsKey('azkarReminderEnabled'), isFalse);
      // Device state is untouched.
      expect(prefs.getInt('contentCacheVersion'), 4);
    });
  });

  group('white text on tile colours', () {
    // The home screen's category seeds.
    const seeds = [
      Color(0xFF64B5F6),
      Color(0xFFF06292),
      Color(0xFF4DB6AC),
      Color(0xFFFFCA28),
      Color(0xFFFFB74D),
      Color(0xFFE57373),
      Color(0xFFAED581),
      Color(0xFFBA68C8),
      Color(0xFF4DD0E1),
      Color(0xFF90A4AE),
      Color(0xFF7986CB),
      Color(0xFFFF8A65),
      // The old lemon yellow, whose labels could not be read.
      Color(0xFFFFF176),
    ];

    test('every seed is darkened until white text is legible', () {
      for (final seed in seeds) {
        expect(
          seed.seedForWhiteText.contrastWithWhite,
          greaterThanOrEqualTo(kMinWhiteTextContrast - 0.01),
          reason: 'seed $seed',
        );
      }
    });

    test('a colour that already passes is left alone', () {
      const navy = Color(0xFF1A237E);
      expect(navy.seedForWhiteText, navy);
    });
  });
}
