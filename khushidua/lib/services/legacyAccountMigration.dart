import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firebaseRef.dart';
import '../controllers/userController.dart';

/// Moves a reader who signed in under the old account system onto the
/// device-only profile, once.
///
/// Their name, avatar and listened duas are copied from their Users document
/// into preferences, so nobody loses progress when accounts go away. Then the
/// device stops being tied to the account: the push token is cleared from the
/// document (announcements now arrive through the topic every install
/// subscribes to, and a token left there would deliver them twice) and the
/// Firebase session is signed out.
///
/// The Users document itself is left in place. Deleting people's records is
/// a decision for the admins, not something an app update should do quietly.
///
/// Not awaited at start-up: it may wait on the network, and the app must
/// open straight away. Returns true when it copied a profile, so the caller
/// can reload the profile controller.
abstract final class LegacyAccountMigration {
  static const _kDone = 'legacyAccountMigrated';
  static const _kAttempts = 'legacyAccountMigrationAttempts';

  /// Launches to keep trying on (offline, say) before giving up.
  static const _maxAttempts = 5;

  /// Preferences only the account system used.
  static const _legacyKeys = ['userId', 'isLoggedIn', 'userPoints', 'userName'];

  static Future<bool> run() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return false;
    }
    if (prefs.getBool(_kDone) ?? false) return false;

    final userId = prefs.getString('userId') ?? '';
    // Most installs never had an account and finish here.
    if (userId.isEmpty) {
      await _finish(prefs);
      return false;
    }

    try {
      // currentUser can still be null this early in start-up, before the
      // saved session is restored, so wait for the first auth state.
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 10));
      if (user == null || user.uid != userId) {
        // The session is gone, so the document cannot be read any more.
        await _finish(prefs);
        return false;
      }
      await _copyProfile(prefs, user.uid);
      await FirebaseAuth.instance.signOut();
      await _finish(prefs);
      return true;
    } catch (e) {
      // Offline, or the document is unreadable: try again next launch rather
      // than losing the progress for good, but not forever.
      final attempts = (prefs.getInt(_kAttempts) ?? 0) + 1;
      debugPrint('LegacyAccountMigration: attempt $attempts failed: $e');
      if (attempts >= _maxAttempts) {
        await _finish(prefs);
      } else {
        await prefs.setInt(_kAttempts, attempts);
      }
      return false;
    }
  }

  static Future<void> _finish(SharedPreferences prefs) async {
    for (final key in [..._legacyKeys, _kAttempts]) {
      await prefs.remove(key);
    }
    await prefs.setBool(_kDone, true);
  }

  static Future<void> _copyProfile(SharedPreferences prefs, String uid) async {
    final doc = await userRef.doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    final name = (data['name'] as String? ?? '').trim();
    if (name.isNotEmpty &&
        (prefs.getString(UserController.kNameKey) ?? '').isEmpty) {
      await prefs.setString(UserController.kNameKey, name);
    }

    final avatar = data['avatar'] as String? ?? '';
    if (avatar.isNotEmpty) {
      await prefs.setString(UserController.kAvatarKey, avatar);
    }

    final listened = {
      ...prefs.getStringList(UserController.kListenedKey) ?? const <String>[],
      ...List<String>.from(data['readDuas'] ?? const []),
    };
    await prefs.setStringList(UserController.kListenedKey, listened.toList());

    try {
      await userRef.doc(uid).update({'fcmToken': '', 'isLoggedIn': false});
    } catch (e) {
      // Not worth blocking the migration over; the worst case is a
      // duplicate announcement on this device.
      debugPrint('LegacyAccountMigration: clearing token failed: $e');
    }
  }
}
