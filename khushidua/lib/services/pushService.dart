import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/userController.dart';
import 'reminderService.dart';

/// Firebase Cloud Messaging for admin announcements.
///
/// Before this, push was only half wired: permission was requested on iOS
/// alone (Android 13+ needs it too, so nothing displayed there), messages
/// arriving while the app was open were ignored, and a rotated token was never
/// written back, so push stopped for good once the token changed.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;
  bool _started = false;

  /// Called by the dashboard when the user taps a push, so it can open the
  /// inbox. Set before [start].
  void Function()? onOpenInbox;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      // Covers Android 13+'s POST_NOTIFICATIONS as well as iOS.
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      // iOS: show the system banner even in the foreground.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('🔔 PushService: permission request failed: $e');
    }

    _foreground = FirebaseMessaging.onMessage.listen(_showForeground);
    _opened = FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());
    _tokenRefresh = _messaging.onTokenRefresh.listen(saveToken);

    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _openInbox();
    } catch (e) {
      debugPrint('🔔 PushService: reading launch message failed: $e');
    }

    // Also refresh on every launch: the stored token may predate a reinstall.
    try {
      final token = await _messaging.getToken();
      if (token != null) await saveToken(token);
    } catch (e) {
      debugPrint('🔔 PushService: reading token failed: $e');
    }
  }

  /// Writes [token] to the signed-in user's document. A guest has no document,
  /// so there is nothing to write; the token is saved again at sign-in.
  Future<void> saveToken(String token) async {
    final user = Get.isRegistered<UserController>()
        ? Get.find<UserController>().userModel
        : null;
    if (user == null || user.fcmToken == token) return;
    try {
      await userRef.doc(user.id).update({'fcmToken': token});
    } catch (e) {
      debugPrint('🔔 PushService: saving token failed: $e');
    }
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    // Android draws nothing for a foreground message; iOS does, via the
    // presentation options above, so drawing here would show it twice.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    ReminderService.instance.showNow(
      id: message.messageId?.hashCode ?? DateTime.now().millisecond,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: 'inbox',
    );
  }

  void _openInbox() => onOpenInbox?.call();

  Future<void> stop() async {
    await _foreground?.cancel();
    await _opened?.cancel();
    await _tokenRefresh?.cancel();
    _started = false;
  }
}
