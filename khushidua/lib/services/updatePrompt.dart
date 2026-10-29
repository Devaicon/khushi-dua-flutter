import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/firebaseRef.dart';
import '../models/appVersion.dart';
import '../models/storeLinks.dart';

/// Asks readers on an old build to update, using the builds set in the admin
/// panel's App Controls tab (`SystemConfiguration/AppVersion`).
///
/// Below the latest build the prompt can be put off, and then stays away for
/// [_snooze]; below the minimum build it cannot be closed.
abstract final class UpdatePrompt {
  static const String _snoozedAt = 'updatePromptSnoozedAt';
  static const Duration _snooze = Duration(days: 1);

  static bool _checked = false;

  /// Checks once per launch. Quietly does nothing when offline.
  static Future<void> check() async {
    if (_checked || !(Platform.isAndroid || Platform.isIOS)) return;
    _checked = true;
    try {
      final (versionDoc, linksDoc, info) = await (
        sysConfigRef.doc(AppVersion.docId).get(),
        sysConfigRef.doc(StoreLinks.docId).get(),
        PackageInfo.fromPlatform(),
      ).wait.timeout(const Duration(seconds: 10));
      final versions = AppVersion.fromMap(versionDoc.data());
      final links = StoreLinks.fromMap(linksDoc.data());
      final build = int.tryParse(info.buildNumber) ?? 0;

      final latest = Platform.isIOS
          ? versions.iosLatest
          : versions.androidLatest;
      final min = Platform.isIOS ? versions.iosMin : versions.androidMin;
      final storeUrl = Platform.isIOS ? links.appStore : links.playStore;

      if (build < min) {
        await _show(storeUrl, required: true);
      } else if (build < latest && await _due()) {
        await _show(storeUrl, required: false);
      }
    } catch (e) {
      debugPrint('⬆️ Update check skipped: $e');
    }
  }

  static Future<bool> _due() async {
    final prefs = await SharedPreferences.getInstance();
    final at = prefs.getInt(_snoozedAt);
    return at == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) >
            _snooze;
  }

  static Future<void> _show(String storeUrl, {required bool required}) {
    return Get.dialog(
      PopScope(
        canPop: !required,
        child: AlertDialog(
          title: Text('Update available'.tr),
          content: Text(
            required
                ? 'This version of Khushi Dua is no longer supported. Please update to continue.'
                      .tr
                : 'A new version of Khushi Dua is ready with the latest fixes and improvements.'
                      .tr,
          ),
          actions: [
            if (!required)
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(
                    _snoozedAt,
                    DateTime.now().millisecondsSinceEpoch,
                  );
                  Get.back();
                },
                child: Text('Later'.tr),
              ),
            FilledButton(
              // A required prompt stays open, so coming back from the store
              // without updating lands on it again.
              onPressed: () {
                launchUrl(
                  Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication,
                );
                if (!required) Get.back();
              },
              child: Text('Update now'.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: !required,
    );
  }
}
