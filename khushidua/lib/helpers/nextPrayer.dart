/// Which prayer is next, for the prayer screen's countdown card.
///
/// Kept free of Flutter and plugin imports so it can be unit tested.
library;

/// The first of [today] (prayer name → start time, in day order) that is
/// still ahead of [now]. After the last one has passed, tomorrow's Fajr.
///
/// The card used to look only at the day being browsed, so it vanished after
/// Isha, froze on a past day, and counted down to a day the reader had merely
/// paged to.
({String name, DateTime time})? nextPrayerAfter({
  required DateTime now,
  required Map<String, DateTime?> today,
  DateTime? tomorrowFajr,
}) {
  for (final entry in today.entries) {
    final time = entry.value;
    if (time != null && time.isAfter(now)) {
      return (name: entry.key, time: time);
    }
  }
  if (tomorrowFajr != null && tomorrowFajr.isAfter(now)) {
    return (name: 'Fajr', time: tomorrowFajr);
  }
  return null;
}
