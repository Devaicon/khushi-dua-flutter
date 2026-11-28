import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'reminderService.dart';

/// Firebase Cloud Messaging for admin announcements.
///
/// Before this, push was only half wired: permission was requested on iOS
/// alone (Android 13+ needs it too, so nothing displayed there), messages
/// arriving while the app was open were ignored, and a rotated token was never
/// written back, so push stopped for good once the token changed.
///
/// Announcements are addressed to the [announcementsTopic] topic, which every
/// install subscribes to. They used to go to the tokens saved on user
/// accounts, so anyone who had not signed in never received a push.
class PushService {
  /// Must match the topic the sendGlobalNotification Cloud Function uses.
  static const String announcementsTopic = 'announcements';

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
    // A refreshed token is re-subscribed by FCM itself; subscribing again is
    // harmless and covers a reinstall that lost the subscription.
    _tokenRefresh = _messaging.onTokenRefresh.listen((_) => _subscribe());

    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _openInbox();
    } catch (e) {
      debugPrint('🔔 PushService: reading launch message failed: $e');
    }

    await _subscribe();
  }

  /// Every launch: subscribing is idempotent, and a launch made offline
  /// gets another chance next time.
  Future<void> _subscribe() async {
    try {
      await _messaging.subscribeToTopic(announcementsTopic);
    } catch (e) {
      // iOS throws until the APNs token exists, e.g. on a simulator.
      debugPrint('🔔 PushService: topic subscription failed: $e');
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
