import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/azkarReminders.dart';
import '../helpers/reminderSchedule.dart';
import '../services/reminderService.dart';

/// User-facing reminder settings, persisted to SharedPreferences.
///
/// Holds the Azkar reminder state and the Salah master switch. The per-prayer
/// on/vibrate/off toggles continue to live under the `[prayer]Speaker` keys
/// written by the prayer screen; this controller reads them when deciding
/// which Salah reminders to schedule.
class ReminderController extends GetxController {
  static const _kAzkarEnabled = 'azkarReminderEnabled';
  static const _kMorningHour = 'azkarMorningHour';
  static const _kMorningMinute = 'azkarMorningMinute';
  static const _kEveningHour = 'azkarEveningHour';
  static const _kEveningMinute = 'azkarEveningMinute';
  static const _kSalahEnabled = 'salahReminderEnabled';
  static const _kPrayerTimes = 'lastKnownPrayerTimes';

  bool _azkarEnabled = false;
  bool get azkarEnabled => _azkarEnabled;

  bool _salahEnabled = false;
  bool get salahEnabled => _salahEnabled;

  TimeOfDay _morningTime = const TimeOfDay(
    hour: kDefaultMorningHour,
    minute: kDefaultMorningMinute,
  );
  TimeOfDay get morningTime => _morningTime;

  TimeOfDay _eveningTime = const TimeOfDay(
    hour: kDefaultEveningHour,
    minute: kDefaultEveningMinute,
  );
  TimeOfDay get eveningTime => _eveningTime;

  /// Latest computed prayer times, kept so the Salah reminders can be
  /// rescheduled when the master switch flips without waiting for the prayer
  /// screen to recompute.
  Map<String, DateTime> _prayerTimes = {};
  Map<String, DateTime> get prayerTimes => Map.unmodifiable(_prayerTimes);

  /// Identifies the banner the user has dismissed, as `prayer@epochMillis`,
  /// so a
  /// dismissal applies to that one occurrence and not to tomorrow's.
  String? _dismissedBanner;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _azkarEnabled = prefs.getBool(_kAzkarEnabled) ?? false;
    _salahEnabled = prefs.getBool(_kSalahEnabled) ?? false;
    _morningTime = TimeOfDay(
      hour: prefs.getInt(_kMorningHour) ?? kDefaultMorningHour,
      minute: prefs.getInt(_kMorningMinute) ?? kDefaultMorningMinute,
    );
    _eveningTime = TimeOfDay(
      hour: prefs.getInt(_kEveningHour) ?? kDefaultEveningHour,
      minute: prefs.getInt(_kEveningMinute) ?? kDefaultEveningMinute,
    );
    update();

    _restorePrayerTimes(prefs);
    update();

    // Re-arm on every launch: pending alarms do not survive some reboots or
    // app updates, and the OS may have dropped them.
    if (_azkarEnabled) await _scheduleAzkar();
  }

  /// Prayer times are stored as minutes-since-midnight and rehydrated onto
  /// today's date, so the banner works before the prayer screen has run. They
  /// are replaced with exact values as soon as it does.
  void _restorePrayerTimes(SharedPreferences prefs) {
    final stored = prefs.getStringList(_kPrayerTimes);
    if (stored == null) return;

    final now = DateTime.now();
    final restored = <String, DateTime>{};
    for (final entry in stored) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final minutes = int.tryParse(parts[1]);
      if (minutes == null) continue;
      restored[parts[0]] = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(minutes: minutes));
    }
    _prayerTimes = restored;
  }

  Future<void> _persistPrayerTimes(SharedPreferences prefs) async {
    await prefs.setStringList(_kPrayerTimes, [
      for (final e in _prayerTimes.entries)
        '${e.key}|${e.value.hour * 60 + e.value.minute}',
    ]);
  }

  /// The prayer whose in-app banner window is open and not dismissed.
  ({String name, DateTime time})? activeSalahBanner() {
    if (!_salahEnabled) return null;

    final now = DateTime.now();
    for (final prayer in kSchedulablePrayers) {
      final time = _prayerTimes[prayer];
      if (time == null) continue;
      if (!isWithinBannerWindow(time, now)) continue;
      if (_dismissedBanner == _bannerKey(prayer, time)) continue;
      return (name: prayer, time: time);
    }
    return null;
  }

  void dismissSalahBanner(String prayer, DateTime time) {
    _dismissedBanner = _bannerKey(prayer, time);
    update();
  }

  String _bannerKey(String prayer, DateTime time) =>
      '$prayer@${time.millisecondsSinceEpoch}';

  /// Turns the Azkar reminders on or off. Returns false when the user declined
  /// the notification permission, in which case the switch stays off.
  Future<bool> setAzkarEnabled(bool value) async {
    if (value) {
      final granted = await ReminderService.instance.requestPermissions();
      if (!granted) return false;
    }

    _azkarEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAzkarEnabled, value);

    if (value) {
      await _scheduleAzkar();
    } else {
      await ReminderService.instance.cancel(kAzkarMorningNotificationId);
      await ReminderService.instance.cancel(kAzkarEveningNotificationId);
    }
    update();
    return true;
  }

  Future<void> setMorningTime(TimeOfDay time) async {
    _morningTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMorningHour, time.hour);
    await prefs.setInt(_kMorningMinute, time.minute);
    if (_azkarEnabled) await _scheduleAzkar();
    update();
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    _eveningTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEveningHour, time.hour);
    await prefs.setInt(_kEveningMinute, time.minute);
    if (_azkarEnabled) await _scheduleAzkar();
    update();
  }

  Future<void> _scheduleAzkar() async {
    await ReminderService.instance.scheduleDaily(
      id: kAzkarMorningNotificationId,
      channelId: ReminderService.azkarChannelId,
      channelName: 'Azkar Reminders',
      title: 'Morning Azkar'.tr,
      body: 'Time for your morning Azkar'.tr,
      hour: _morningTime.hour,
      minute: _morningTime.minute,
      payload: 'azkar:$kMorningAzkarCategoryId',
    );
    await ReminderService.instance.scheduleDaily(
      id: kAzkarEveningNotificationId,
      channelId: ReminderService.azkarChannelId,
      channelName: 'Azkar Reminders',
      title: 'Evening Azkar'.tr,
      body: 'Time for your evening Azkar'.tr,
      hour: _eveningTime.hour,
      minute: _eveningTime.minute,
      payload: 'azkar:$kEveningAzkarCategoryId',
    );
  }

  /// Turns the Salah reminders on or off. Returns false when the user declined
  /// the notification permission.
  Future<bool> setSalahEnabled(bool value) async {
    if (value) {
      final granted = await ReminderService.instance.requestPermissions();
      if (!granted) return false;
    }

    _salahEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSalahEnabled, value);
    await syncSalahReminders(_prayerTimes);
    update();
    return true;
  }

  /// Rescheduled by the prayer screen whenever the times are recomputed — a
  /// location change, a calculation-method change, or a new day.
  Future<void> syncSalahReminders(Map<String, DateTime> times) async {
    final prefs = await SharedPreferences.getInstance();

    if (times.isNotEmpty) {
      _prayerTimes = times;
      await _persistPrayerTimes(prefs);
    }

    for (final prayer in kSchedulablePrayers) {
      final id = notificationIdFor(prayer);
      final time = _prayerTimes[prayer];

      // "off" silences a single prayer; the master switch silences all of them.
      final mode = prefs.getString(_speakerKeyFor(prayer)) ?? 'on';
      final wanted = _salahEnabled && mode != 'off' && time != null;

      if (!wanted) {
        await ReminderService.instance.cancel(id);
        continue;
      }

      await ReminderService.instance.scheduleDaily(
        id: id,
        channelId: ReminderService.salahChannelId,
        channelName: 'Salah Reminders',
        title: '${prayer.tr} ${'time'.tr}',
        body: '${'It is time for'.tr} ${prayer.tr}',
        hour: time.hour,
        minute: time.minute,
        payload: 'salah:$prayer',
      );
    }
    update();
  }

  /// Mirrors the key naming already used by the prayer screen.
  String _speakerKeyFor(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return 'fajrSpeaker';
      case 'Dhuhr':
        return 'dhuhrSpeaker';
      case 'Asr':
        return 'asrSpeaker';
      case 'Maghrib':
        return 'maghribSpeaker';
      case 'Ishaa':
        return 'ishaSpeaker';
      default:
        return '${prayer.toLowerCase()}Speaker';
    }
  }
}
