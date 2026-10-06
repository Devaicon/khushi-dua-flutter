import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';

/// Light, dark, or following the phone.
///
/// The colour tokens in colors.dart and theme.dart read [AppPalette.isDark]
/// directly, so screens need no context to pick a colour. When it flips,
/// every widget is rebuilt and repainted once, which is what a theme change
/// needs and is rare enough not to matter.
class AppearanceController extends GetxController with WidgetsBindingObserver {
  static const String _kMode = 'appearance';

  /// Stored value → label, in the order the picker lists them.
  static const Map<String, String> modes = {
    'system': 'System default',
    'light': 'Light',
    'dark': 'Dark',
  };

  static String _savedMode = 'system';

  /// Read before runApp, so the first frame is already in the right theme.
  static Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kMode);
      if (modes.containsKey(stored)) _savedMode = stored!;
    } catch (_) {
      // A broken preferences store must not stop the app from launching.
    }
    AppPalette.isDark = resolveDark(_savedMode, _platformIsDark);
  }

  static bool get _platformIsDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  static bool resolveDark(String mode, bool platformIsDark) => switch (mode) {
    'dark' => true,
    'light' => false,
    _ => platformIsDark,
  };

  String _mode = _savedMode;
  String get mode => _mode;

  bool get isDark => AppPalette.isDark;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// The phone switched between light and dark; matters only on 'system'.
  @override
  void didChangePlatformBrightness() => _apply();

  Future<void> setMode(String value) async {
    if (!modes.containsKey(value) || value == _mode) return;
    _mode = value;
    _apply();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, value);
  }

  void _apply() {
    final dark = resolveDark(_mode, _platformIsDark);
    if (dark == AppPalette.isDark) {
      update();
      return;
    }
    AppPalette.isDark = dark;
    // The app's theme, then everything that read a token directly.
    update();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.forceAppUpdate());
  }
}
