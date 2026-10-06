import 'package:get/get.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How prayer times are calculated: the calculation method and the juristic
/// method (madhab) for Asr.
///
/// Changed on the Prayer Times settings screen, which opens from both the
/// prayer screen and Settings; the prayer screen listens and recalculates.
class PrayerSettingsController extends GetxController {
  static const _kMethod = 'calculationMethod';
  static const _kMadhab = 'juristicMethod';

  static const String defaultMethod = 'karachi';
  static const String defaultMadhab = 'shafi';

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

  String _method = defaultMethod;
  String get method => _method;

  String _madhab = defaultMadhab;
  String get madhab => _madhab;

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
