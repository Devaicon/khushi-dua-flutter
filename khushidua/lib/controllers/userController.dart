import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization.dart';

/// The reader's profile, kept on this device only. There are no accounts:
/// nothing here is sent anywhere, and nothing in the app waits for it.
///
/// Holds the optional display name and avatar, the app language and the
/// duas listened to all the way through. Moving to another phone is done by
/// exporting and importing settings (see SettingsBackup), not by signing in.
class UserController extends GetxController {
  static const String kNameKey = 'profileName';
  static const String kAvatarKey = 'userAvatar';
  static const String kListenedKey = 'listenedDuas';
  static const String kLanguageKey = 'selectedLanguage';

  /// What listening to one dua to the end used to earn on an account. Points
  /// are now derived from the listened duas, so they can never disagree.
  static const int pointsPerDua = 50;

  String _userName = '';

  /// Empty until the reader chooses to give one.
  String get userName => _userName;
  bool get hasName => _userName.isNotEmpty;

  String _avatar = '';
  String get avatar => _avatar;

  String _selectedLanguage = 'English';
  String get selectedLanguage => _selectedLanguage;

  final Set<String> _listened = {};

  /// Ids of the duas whose audio has played to the end on this device.
  Set<String> get listenedDuas => Set.unmodifiable(_listened);
  bool isListened(String duaId) => _listened.contains(duaId);
  int get listenedCount => _listened.length;
  int get points => _listened.length * pointsPerDua;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Reads the profile from preferences. Called again after an import.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = (prefs.getString(kNameKey) ?? '').trim();
    _avatar = prefs.getString(kAvatarKey) ?? '';
    _listened
      ..clear()
      ..addAll(prefs.getStringList(kListenedKey) ?? const []);
    setSelectedLanguage(prefs.getString(kLanguageKey) ?? 'English');
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    Localization.changeLocale(language);
    update();
  }

  Future<void> setUserName(String value) async {
    _userName = value.trim();
    update();
    final prefs = await SharedPreferences.getInstance();
    if (_userName.isEmpty) {
      await prefs.remove(kNameKey);
    } else {
      await prefs.setString(kNameKey, _userName);
    }
  }

  Future<void> setAvatar(String value) async {
    _avatar = value;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAvatarKey, value);
  }

  /// Records that [duaId]'s audio played to the end.
  Future<void> markListened(String duaId) async {
    if (duaId.isEmpty || !_listened.add(duaId)) return;
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kListenedKey, _listened.toList());
  }
}
