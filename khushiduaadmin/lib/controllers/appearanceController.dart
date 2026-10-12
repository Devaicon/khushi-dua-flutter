import 'dart:html' as html;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';

/// Light, dark, or following the computer, as in the app's Settings.
///
/// The colour tokens read [Palette.isDark] directly, so widgets need no
/// context to pick a colour. When it flips, every widget is rebuilt once.
/// The choice is kept in this browser's local storage.
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
  static void loadSaved() {
    try {
      final stored = html.window.localStorage[_kMode];
      if (modes.containsKey(stored)) _savedMode = stored!;
    } catch (_) {
      // Storage can be blocked (private windows); fall back to the system.
    }
    Palette.isDark = resolveDark(_savedMode, _platformIsDark);
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

  /// The computer switched between light and dark; matters on 'system'.
  @override
  void didChangePlatformBrightness() => _apply();

  void setMode(String value) {
    if (!modes.containsKey(value) || value == _mode) return;
    _mode = value;
    try {
      html.window.localStorage[_kMode] = value;
    } catch (_) {}
    _apply();
  }

  void _apply() {
    final dark = resolveDark(_mode, _platformIsDark);
    if (dark == Palette.isDark) {
      update();
      return;
    }
    Palette.isDark = dark;
    // The theme, then everything that read a token directly.
    update();
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.forceAppUpdate());
  }
}
