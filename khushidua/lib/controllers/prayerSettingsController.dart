import 'package:flutter/material.dart' show DateUtils;
import 'package:get/get.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/hijriDate.dart';

/// How prayer times are calculated: the calculation method and the juristic
/// method (madhab) for Asr. Also the adjustment to the Islamic date, which
/// sits on the same settings screen.
///
/// Changed on the Prayer Times settings screen, which opens from both the
/// prayer screen and Settings; the prayer screen listens and recalculates.
class PrayerSettingsController extends GetxController {
  static const _kMethod = 'calculationMethod';
  static const _kMadhab = 'juristicMethod';
  static const _kCardStyle = 'nextPrayerCardStyle';
  static const _kHijriOffset = 'hijriOffset';
  static const _kCountryCode = 'lastCountryCode';

  static const String defaultMethod = 'karachi';
  static const String defaultMadhab = 'shafi';
  static const String defaultCardStyle = 'progress';
  static const String autoHijriOffset = 'auto';

  /// Stored value → label, in the order the picker lists them. The stored
  /// values are the names the app has always saved, so existing choices
  /// carry over.
  static const Map<String, String> methods = {
    'egyptian': 'Egyptian General Authority of Survey',
    'karachi': 'University of Islamic Sciences, Karachi',
    'ummAlQura': 'Umm al-Qura University, Makkah',
    'northAmerica': 'Islamic Society of North America',
    'muslimWorldLeague': 'Muslim World League',
    'turkey': 'Presidency of Religious Affairs, Turkey',
  };

  static const Map<String, String> madhabs = {
    'shafi': 'Shafi, Maliki, Hanbali',
    'hanafi': 'Hanafi',
  };

  /// What the next-prayer card shows under its countdown.
  static const Map<String, String> cardStyles = {
    'progress': 'Progress bar',
    'sun': 'Sun path',
  };

  /// Stored value → label for the Islamic date adjustment. "auto" picks it
  /// from the reader's country; the rest are days added to Umm al-Qura.
  static const Map<String, String> hijriOffsets = {
    autoHijriOffset: 'Automatic',
    '-2': '2 days behind',
    '-1': '1 day behind',
    '0': 'Same as Makkah',
    '1': '1 day ahead',
    '2': '2 days ahead',
  };

  String _method = defaultMethod;
  String get method => _method;

  String _madhab = defaultMadhab;
  String get madhab => _madhab;

  String _cardStyle = defaultCardStyle;
  String get cardStyle => _cardStyle;

  String _hijriOffsetChoice = autoHijriOffset;
  String get hijriOffsetChoice => _hijriOffsetChoice;

  /// Where the reader was last located, kept so the automatic adjustment is
  /// right on the next launch before the location comes back.
  String? _countryCode;
  String? get countryCode => _countryCode;

  /// Days added to the Umm al-Qura date.
  int get hijriOffset => _hijriOffsetChoice == autoHijriOffset
      ? defaultHijriOffset(_countryCode)
      : int.parse(_hijriOffsetChoice);

  DateTime? _todayMaghrib;

  /// Today's Maghrib, reported by the prayer screen, so the settings preview
  /// changes date at the same moment the prayer screen does. Null once the
  /// day it was reported for has passed.
  DateTime? get todayMaghrib =>
      _todayMaghrib != null &&
          DateUtils.isSameDay(_todayMaghrib, DateTime.now())
      ? _todayMaghrib
      : null;
  set todayMaghrib(DateTime? value) => _todayMaghrib = value;

  /// Becomes true once the stored choices are read, so the prayer screen does
  /// not calculate once with the defaults and again with the real values.
  bool _loaded = false;
  bool get loaded => _loaded;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _method = normaliseMethod(prefs.getString(_kMethod));
    _madhab = madhabs.containsKey(prefs.getString(_kMadhab))
        ? prefs.getString(_kMadhab)!
        : defaultMadhab;
    _cardStyle = cardStyles.containsKey(prefs.getString(_kCardStyle))
        ? prefs.getString(_kCardStyle)!
        : defaultCardStyle;
    _hijriOffsetChoice =
        hijriOffsets.containsKey(prefs.getString(_kHijriOffset))
        ? prefs.getString(_kHijriOffset)!
        : autoHijriOffset;
    _countryCode = prefs.getString(_kCountryCode);
    _loaded = true;
    update();
  }

  /// A method that is no longer offered (Singapore was, once) falls back to
  /// the default rather than leaving the picker without a selection.
  static String normaliseMethod(String? stored) =>
      methods.containsKey(stored) ? stored! : defaultMethod;

  Future<void> setMethod(String value) async {
    if (!methods.containsKey(value) || value == _method) return;
    _method = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMethod, value);
  }

  Future<void> setMadhab(String value) async {
    if (!madhabs.containsKey(value) || value == _madhab) return;
    _madhab = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMadhab, value);
  }

  Future<void> setCardStyle(String value) async {
    if (!cardStyles.containsKey(value) || value == _cardStyle) return;
    _cardStyle = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCardStyle, value);
  }

  Future<void> setHijriOffset(String value) async {
    if (!hijriOffsets.containsKey(value) || value == _hijriOffsetChoice) return;
    _hijriOffsetChoice = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHijriOffset, value);
  }

  /// Records the ISO country code of the reader's location.
  Future<void> setCountryCode(String value) async {
    final code = value.toUpperCase();
    if (code.isEmpty || code == _countryCode) return;
    _countryCode = code;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCountryCode, code);
  }

  /// Fresh parameters for the current choices. A new object every call: the
  /// package's parameters are mutable, and the madhab is set on them.
  PrayerCalculationParameters get parameters {
    final params = switch (_method) {
      'egyptian' => PrayerCalculationMethod.egyptian(),
      'ummAlQura' => PrayerCalculationMethod.ummAlQura(),
      'northAmerica' => PrayerCalculationMethod.northAmerica(),
      'muslimWorldLeague' => PrayerCalculationMethod.muslimWorldLeague(),
      'turkey' => PrayerCalculationMethod.turkey(),
      _ => PrayerCalculationMethod.karachi(),
    };
    params.madhab = _madhab == 'hanafi'
        ? PrayerMadhab.hanafi
        : PrayerMadhab.shafi;
    return params;
  }
}
