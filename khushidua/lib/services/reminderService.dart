import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/reminderSchedule.dart';

/// Owns the local-notification plugin: initialisation, permissions, and the
/// scheduling of the Azkar and Salah reminders.
///
/// The app had no local notifications before this, so everything here is new.
/// Push (`firebase_messaging`) is separate and untouched.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const String azkarChannelId = 'azkar_reminders';

  /// Android fixes a channel's sound when the channel is first created, so
  /// adding the Salah sound needed a new channel id. The old one is deleted in
  /// [init].
  static const String salahChannelId = 'salah_reminders_haya';
  static const String salahVibrateChannelId = 'salah_reminders_vibrate';
  static const String _legacySalahChannelId = 'salah_reminders';

  /// `android/app/src/main/res/raw/haya_al_salah.mp3`. Android resource names
  /// allow only lowercase letters, digits and underscores.
  static const String salahSoundAndroid = 'haya_al_salah';

  /// `ios/Runner/haya_al_salah.wav`. iOS notification sounds must be WAV,
  /// AIFF or CAF, under 30 seconds, and bundled with the app.
  static const String salahSoundIos = 'haya_al_salah.wav';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool get isInitialised => _initialised;

  /// Set when a notification launched or resumed the app, so the UI can route
  /// to the right screen once it is ready.
  String? pendingPayload;

  /// Called by the dashboard once it can navigate.
  void Function(String payload)? onNotificationTap;

  Future<void> init() async {
    if (_initialised) return;

    try {
      tzdata.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      // A missing or unrecognised zone must not stop the app from starting;
      // scheduling then falls back to whatever tz.local defaults to (UTC).
      debugPrint('⏰ ReminderService: timezone setup failed: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      // Requested explicitly in requestPermissions() instead, so the prompt
      // appears when the user enables a reminder rather than at first launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: _handleResponse,
        onDidReceiveBackgroundNotificationResponse:
            notificationTapBackground,
      );

      await _createAndroidChannels();

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        pendingPayload = launchDetails?.notificationResponse?.payload;
      }

      _initialised = true;
    } catch (e) {
      debugPrint('⏰ ReminderService: initialisation failed: $e');
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    try {
      await android.deleteNotificationChannel(_legacySalahChannelId);
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          salahChannelId,
          'Salah Reminders',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(salahSoundAndroid),
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          salahVibrateChannelId,
          'Salah Reminders (vibrate only)',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
        ),
      );
    } catch (e) {
      debugPrint('⏰ ReminderService: creating channels failed: $e');
    }
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final handler = onNotificationTap;
    if (handler != null) {
      handler(payload);
    } else {
      pendingPayload = payload;
    }
  }

  /// Asks for notification permission. Returns false if the user declined, so
  /// callers can leave their toggle off rather than lying about being armed.
  Future<bool> requestPermissions() async {
    await init();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('⏰ ReminderService: permission request failed: $e');
    }
    return false;
  }

  /// Schedules a daily repeating notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    bool playSound = true,
    String? androidSound,
    String? iosSound,
  }) async {
    await init();

    final next = nextOccurrence(
      hour: hour,
      minute: minute,
      now: DateTime.now(),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(next, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: playSound,
            sound: androidSound == null
                ? null
                : RawResourceAndroidNotificationSound(androidSound),
          ),
          iOS: DarwinNotificationDetails(
            presentSound: playSound,
            sound: playSound ? iosSound : null,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Repeats every day at the same wall-clock time.
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint('⏰ ReminderService: scheduling id $id failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    await init();
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('⏰ ReminderService: cancelling id $id failed: $e');
    }
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('⏰ ReminderService: reading pending failed: $e');
      return const [];
    }
  }
}

/// Must be a top-level function for the plugin's background isolate.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('⏰ Background notification tap: ${response.payload}');
}
