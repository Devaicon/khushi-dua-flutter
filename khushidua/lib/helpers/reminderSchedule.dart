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

/// The stable notification id for a prayer, or -1 if it is not schedulable.
int notificationIdFor(String prayerName) {
  final index = kSchedulablePrayers.indexOf(prayerName);
  return index == -1 ? -1 : _kSalahIdBase + index;
}
