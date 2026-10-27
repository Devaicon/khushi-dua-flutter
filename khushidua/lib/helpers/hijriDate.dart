/// The Islamic (Hijri) date shown on the prayer screen.
///
/// The `hijri` package follows Saudi Arabia's Umm al-Qura calendar, but most
/// countries start each month on their own moon sighting. Pakistan, India and
/// Bangladesh are usually a day behind Makkah, so they get a -1 day default;
/// the reader can override it in Prayer Times settings. The Islamic day also
/// begins at Maghrib, not midnight.
///
/// Kept free of Flutter and GetX so it can be unit tested.
library;

import 'package:hijri/hijri_calendar.dart';

/// The adjustments the reader can pick, in days.
const int kMinHijriOffset = -2;
const int kMaxHijriOffset = 2;

/// Countries whose moon sighting usually runs a day behind Umm al-Qura.
const Set<String> kOneDayBehindMakkah = {'PK', 'IN', 'BD'};

/// The adjustment used when the reader has not picked one, from the ISO
/// country code of their location (null when it is not known yet).
int defaultHijriOffset(String? isoCountryCode) =>
    kOneDayBehindMakkah.contains(isoCountryCode?.toUpperCase()) ? -1 : 0;

/// The Hijri date for the civil day [date], moved by [offsetDays].
///
/// When [maghrib] is given (only for today) and [now] is at or past it, the
/// date is the next day's: the Islamic day has already begun.
HijriCalendar hijriDateFor(
  DateTime date, {
  required int offsetDays,
  DateTime? maghrib,
  DateTime? now,
}) {
  var days = offsetDays;
  if (maghrib != null && !(now ?? DateTime.now()).isBefore(maghrib)) days++;
  return HijriCalendar.fromDate(
    DateTime(date.year, date.month, date.day + days),
  );
}
