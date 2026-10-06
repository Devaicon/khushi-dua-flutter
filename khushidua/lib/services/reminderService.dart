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

  /// Admin announcements received while the app is open. FCM only draws a
  /// notification itself when the app is in the background.
  static const String pushChannelId = 'admin_announcements';

  /// Android fixes a channel's sound when the channel is first created, so
  /// adding the Salah sound needed a new channel id. The old one is deleted in
  /// [init].
  static const String salahChannelId = 'salah_reminders_haya';
  static const String salahDefaultChannelId = 'salah_reminders_default';

  /// v2: the first vibrate channel shipped without an explicit vibration
  /// pattern, and a channel's settings cannot be changed after creation — so
  /// reaching existing installs needs a new id.
  static const String salahVibrateChannelId = 'salah_reminders_vibrate_v2';
  static const String _legacySalahChannelId = 'salah_reminders';
  static const String _legacyVibrateChannelId = 'salah_reminders_vibrate';

  /// Long enough to be felt through a pocket: wait, buzz, pause, buzz.
  static final Int64List salahVibrationPattern = Int64List.fromList(const [
    0,
    500,
    250,
    500,
  ]);

  /// The notification channel a prayer's reminder should use.
  static String channelIdForSalah(SalahChannel channel) {
    switch (channel) {
      case SalahChannel.haya:
        return salahChannelId;
      case SalahChannel.deviceDefault:
        return salahDefaultChannelId;
      case SalahChannel.vibrate:
      case SalahChannel.none:
        return salahVibrateChannelId;
    }
  }

  /// The user-visible channel name, shown in Android's system settings.
  static String channelNameForSalah(SalahChannel channel) {
    switch (channel) {
      case SalahChannel.haya:
        return 'Salah Reminders';
      case SalahChannel.deviceDefault:
        return 'Salah Reminders (default sound)';
      case SalahChannel.vibrate:
      case SalahChannel.none:
        return 'Salah Reminders (vibrate only)';
    }
  }

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
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          pushChannelId,
          'Announcements',
          importance: Importance.high,
        ),
      );
      await android.deleteNotificationChannel(_legacySalahChannelId);
      await android.deleteNotificationChannel(_legacyVibrateChannelId);
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
          salahDefaultChannelId,
          'Salah Reminders (default sound)',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          salahVibrateChannelId,
          'Salah Reminders (vibrate only)',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: salahVibrationPattern,
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
    bool vibrate = true,
  }) async {
    await _schedule(
      id: id,
      when: nextOccurrence(hour: hour, minute: minute, now: DateTime.now()),
      // Repeats every day at the same wall-clock time.
      repeat: DateTimeComponents.time,
      title: title,
      body: body,
      payload: payload,
      details: _details(
        channelId: channelId,
        channelName: channelName,
        playSound: playSound,
        androidSound: androidSound,
        iosSound: iosSound,
        vibrate: vibrate,
      ),
    );
  }

  /// Schedules a notification repeating every week on [weekday] at
  /// [hour]:[minute], on the announcements channel.
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _schedule(
      id: id,
      when: nextWeekdayOccurrence(
        weekday: weekday,
        hour: hour,
        minute: minute,
        now: DateTime.now(),
      ),
      repeat: DateTimeComponents.dayOfWeekAndTime,
      title: title,
      body: body,
      payload: payload,
      details: _details(channelId: pushChannelId, channelName: 'Announcements'),
    );
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    bool playSound = true,
    String? androidSound,
    String? iosSound,
    bool vibrate = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: playSound,
        sound: androidSound == null
            ? null
            : RawResourceAndroidNotificationSound(androidSound),
        enableVibration: vibrate,
        vibrationPattern: vibrate && !playSound ? salahVibrationPattern : null,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: playSound,
        sound: playSound ? iosSound : null,
      ),
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required DateTimeComponents repeat,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeat,
        payload: payload,
      );
    } catch (e) {
      debugPrint('⏰ ReminderService: scheduling id $id failed: $e');
    }
  }

  /// Fires a Salah reminder right now through [channel], exactly as a real
  /// one would arrive: same channel, sound and vibration. The OS — not the
  /// app — plays it, so what the user hears is what they will get, including
  /// the effect of Do Not Disturb or a muted channel.
  Future<void> previewSalah(
    SalahChannel channel, {
    required String title,
    required String body,
  }) async {
    await init();
    final useHaya = channel == SalahChannel.haya;
    try {
      await _plugin.show(
        kSalahPreviewNotificationId,
        title,
        body,
        _details(
          channelId: channelIdForSalah(channel),
          channelName: channelNameForSalah(channel),
          playSound: channel != SalahChannel.vibrate,
          androidSound: useHaya ? salahSoundAndroid : null,
          iosSound: useHaya ? salahSoundIos : null,
        ),
      );
    } catch (e) {
      debugPrint('⏰ ReminderService: preview failed: $e');
    }
  }

  /// Shows a notification immediately, on the announcements channel.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            pushChannelId,
            'Announcements',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('⏰ ReminderService: showing id $id failed: $e');
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
