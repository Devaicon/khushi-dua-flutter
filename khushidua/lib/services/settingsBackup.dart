import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/userController.dart';
import '../helpers/reminderSchedule.dart';

/// Everything a reader would want on a new phone, as one JSON file.
///
/// This is how the app moves between devices now that there are no accounts:
/// Settings → Export writes the file, the reader keeps or sends it however
/// they like, and Settings → Import on the other phone reads it back.
///
/// Only the keys listed in [portableKeys] travel. Caches, the last known
/// location and prayer times, inbox markers and the like describe one device
/// and are left behind. Pure Dart apart from SharedPreferences, so the
/// encoding can be unit tested.
abstract final class SettingsBackup {
  /// Identifies the file as ours. Checked on import.
  static const String appId = 'khushidua';

  /// Bumped if the layout changes incompatibly; older files stay readable.
  static const int formatVersion = 1;

  /// The prayers with their own alert and sound choices on the prayer screen.
  static const List<String> _alertPrayers = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Sunset',
    'Ishaa',
  ];

  static final Set<String> portableKeys = {
    // Profile and progress.
    UserController.kNameKey,
    UserController.kAvatarKey,
    UserController.kListenedKey,
    // Look and language.
    UserController.kLanguageKey,
    'appearance',
    'selectedAgeGroup',
    // Prayer times.
    'calculationMethod',
    'juristicMethod',
    'nextPrayerCardStyle',
    'hijriOffset',
    // Reminders.
    'azkarReminderEnabled',
    'azkarMorningHour',
    'azkarMorningMinute',
    'azkarEveningHour',
    'azkarEveningMinute',
    'salahReminderEnabled',
    'supportReminderEnabled',
    for (final prayer in _alertPrayers) ...[
      salahSpeakerKeyFor(prayer),
      salahSoundKeyFor(prayer),
    ],
  };

  /// One-time tips the reader has already dismissed.
  static bool _isPortable(String key) =>
      portableKeys.contains(key) || key.startsWith('tipSeen.');

  /// The reader's settings as pretty-printed JSON.
  static Future<String> export() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, Object>{
      for (final key in prefs.getKeys())
        if (_isPortable(key) && prefs.get(key) != null) key: prefs.get(key)!,
    };
    return encode(values, exportedAt: DateTime.now());
  }

  static String encode(Map<String, Object> values, {DateTime? exportedAt}) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'format': formatVersion,
      if (exportedAt != null) 'exportedAt': exportedAt.toUtc().toIso8601String(),
      // Typed, because JSON cannot tell an int from a double, or a list of
      // strings from any other list, and preferences can.
      'settings': {
        for (final e in values.entries)
          e.key: {'type': _typeOf(e.value), 'value': e.value},
      },
    });
  }

  static String _typeOf(Object value) => switch (value) {
    bool() => 'bool',
    int() => 'int',
    double() => 'double',
    String() => 'string',
    List() => 'stringList',
    _ => throw ArgumentError('Unsupported preference type: $value'),
  };

  /// Parses a backup. Throws [BackupFormatException] for anything that is
  /// not one of our files; unknown or malformed entries are skipped, so a
  /// file from a newer version still restores what this version knows.
  static Map<String, Object> decode(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException();
    }
    if (root is! Map || root['app'] != appId || root['settings'] is! Map) {
      throw const BackupFormatException();
    }
    final format = root['format'];
    if (format is! int || format > formatVersion) {
      throw const BackupFormatException(newerVersion: true);
    }

    final values = <String, Object>{};
    for (final MapEntry(:key, :value) in (root['settings'] as Map).entries) {
      if (key is! String || !_isPortable(key) || value is! Map) continue;
      final parsed = _parse(value['type'], value['value']);
      if (parsed != null) values[key] = parsed;
    }
    return values;
  }

  static Object? _parse(Object? type, Object? value) => switch (type) {
    'bool' when value is bool => value,
    'int' when value is int => value,
    'double' when value is num => value.toDouble(),
    'string' when value is String => value,
    'stringList' when value is List && value.every((v) => v is String) =>
      List<String>.from(value),
    _ => null,
  };

  /// Replaces the portable settings with [values]: keys missing from the
  /// backup are cleared, so the result matches the exporting phone rather
  /// than being a mix of the two. Returns how many settings were written.
  static Future<int> apply(Map<String, Object> values) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(_isPortable).toList()) {
      if (!values.containsKey(key)) await prefs.remove(key);
    }
    for (final MapEntry(:key, :value) in values.entries) {
      switch (value) {
        case bool v:
          await prefs.setBool(key, v);
        case int v:
          await prefs.setInt(key, v);
        case double v:
          await prefs.setDouble(key, v);
        case String v:
          await prefs.setString(key, v);
        case List<String> v:
          await prefs.setStringList(key, v);
      }
    }
    return values.length;
  }
}

class BackupFormatException implements Exception {
  const BackupFormatException({this.newerVersion = false});

  /// The file is ours but was written by a newer version of the app.
  final bool newerVersion;
}
