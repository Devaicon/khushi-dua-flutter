/// Pure scheduling arithmetic shared by the Azkar and Salah reminders.
///
/// Kept free of Flutter and plugin imports so it can be unit tested; the
/// plugin-facing work lives in `services/reminderService.dart`.
library;

/// Notification ids. Stable per reminder so rescheduling replaces the pending
/// alarm instead of stacking a second one on top of it.
const int kAzkarMorningNotificationId = 100;
const int kAzkarEveningNotificationId = 101;

/// Base for the Salah ids; each prayer takes `_kSalahIdBase + its index`.
const int _kSalahIdBase = 200;

/// Prayers that can carry a reminder. Sunrise and Sunset appear in the times
/// list but are not prayers, so they are not schedulable.
const List<String> kSchedulablePrayers = [
  "Fajr",
  "Dhuhr",
  "Asr",
  "Maghrib",
  "Ishaa",
];

/// How long the in-app Salah banner stays up after the prayer time.
const Duration kSalahBannerWindow = Duration(minutes: 20);

/// The next time-of-day occurrence at or after [now].
///
/// Returns tomorrow when the time has already passed today, and also when it
/// falls exactly on [now] — a notification scheduled for the current instant
/// is dropped by the OS rather than shown.
DateTime nextOccurrence({
  required int hour,
  required int minute,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) return today;
  // Adding to the day component rolls months, years and leap days correctly.
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// Whether the in-app banner for a prayer at [prayerTime] should be showing.
///
/// The window opens at the prayer time and closes [kSalahBannerWindow] later;
/// it is deliberately not open beforehand, so the banner always means "it is
/// time now" rather than "it is nearly time".
bool isWithinBannerWindow(DateTime prayerTime, DateTime now) {
  if (now.isBefore(prayerTime)) return false;
  return now.difference(prayerTime) <= kSalahBannerWindow;
}

/// How a single prayer's reminder should alert, from its on/vibrate/off
/// setting on the prayer screen.
enum SalahAlert { sound, vibrate, off }

/// Anything other than "vibrate" or "off" — including a setting that was
/// never saved — plays the Salah sound, matching the prayer screen's default.
SalahAlert salahAlertFor(String? mode) {
  switch (mode) {
    case 'off':
      return SalahAlert.off;
    case 'vibrate':
      return SalahAlert.vibrate;
    default:
      return SalahAlert.sound;
  }
}

/// What a prayer's reminder plays when its alert mode is [SalahAlert.sound].
///
/// Chosen per prayer, independently of the on/vibrate/off mode. A trimmed azan
/// becomes a third value here without any other restructuring.
enum SalahSound { haya, deviceDefault }

/// The stored preference value for a sound choice.
String salahSoundValue(SalahSound sound) =>
    sound == SalahSound.deviceDefault ? 'default' : 'haya';

/// Anything unrecognised — including a setting that was never saved — keeps
/// the Haya al-Salah call, which is what the app shipped with.
SalahSound salahSoundFor(String? value) =>
    value == 'default' ? SalahSound.deviceDefault : SalahSound.haya;

/// Android fixes a channel's sound when the channel is first created, so each
/// distinct sound needs its own channel. A prayer points at one of these; it
/// does not own one.
enum SalahChannel { haya, deviceDefault, vibrate, none }

/// The single place that maps a prayer's two settings onto a channel.
SalahChannel salahChannelFor(SalahAlert alert, SalahSound sound) {
  switch (alert) {
    case SalahAlert.off:
      return SalahChannel.none;
    case SalahAlert.vibrate:
      return SalahChannel.vibrate;
    case SalahAlert.sound:
      return sound == SalahSound.deviceDefault
          ? SalahChannel.deviceDefault
          : SalahChannel.haya;
  }
}

/// The preference key holding a prayer's on/vibrate/off mode.
///
/// Historic naming: Ishaa's key is "isha", not "ishaa".
String salahSpeakerKeyFor(String prayer) =>
    prayer == 'Ishaa' ? 'ishaSpeaker' : '${prayer.toLowerCase()}Speaker';

/// The preference key holding a prayer's sound choice.
String salahSoundKeyFor(String prayer) =>
    prayer == 'Ishaa' ? 'ishaSound' : '${prayer.toLowerCase()}Sound';

/// The stable notification id for a prayer, or -1 if it is not schedulable.
int notificationIdFor(String prayerName) {
  final index = kSchedulablePrayers.indexOf(prayerName);
  return index == -1 ? -1 : _kSalahIdBase + index;
}
