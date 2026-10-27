# Hijri date: per-country adjustment from the admin panel (planned, not built)

**Status:** deferred. Build this when the automatic default is wrong often enough that
waiting for an app release is not acceptable.
**Written:** 2026-10-27

## Why it may be needed

The prayer screen's Islamic date comes from the `hijri` package, which follows Saudi
Arabia's **Umm al-Qura** calendar. Most countries start each month on their own moon
sighting. Pakistan (Ruet-e-Hilal Committee), India and Bangladesh are *usually* one day
behind Makkah, but not every month: sometimes they match Makkah, occasionally they are
two days behind. A fixed default can therefore be a day off for a whole month.

## What the app already does (shipped in 1.6.x)

| Piece | Where |
|---|---|
| **Country default:** −1 day for `PK`, `IN`, `BD`; 0 elsewhere | `defaultHijriOffset()` in `khushidua/lib/helpers/hijriDate.dart` |
| **Reader's manual choice:** Automatic, −2 … +2 days | Prayer Times settings → "Islamic Date"; stored as `hijriOffset` in SharedPreferences by `PrayerSettingsController` |
| **Country of the reader** | Reverse-geocoded on the prayer screen, saved as `lastCountryCode` (`PrayerSettingsController.setCountryCode`) |
| **Date changes at Maghrib** for today | `hijriDateFor(..., maghrib:)` in `hijriDate.dart`, called from `PrayerScreen._hijriDate` |

`PrayerSettingsController.hijriOffset` resolves the final number: the manual choice if
the reader picked one, otherwise `defaultHijriOffset(countryCode)`.

## The plan

Let the team set the adjustment per country in the admin panel. Phones pick it up live,
with no app release. Someone updates it after each moon-sighting announcement (around the
29th of each Hijri month).

### Precedence (highest first)

1. The reader's manual choice in settings (anything other than "Automatic").
2. The admin panel's adjustment for the reader's country, if one is set.
3. The built-in default from `defaultHijriOffset()`. This still applies offline, on first
   launch, and for countries the admin has not listed.

### Firestore

The document is `SystemConfiguration/HijriAdjustment`. That collection is already
public-read and admin-write in `khushidua/firestore.rules`, so no rules change is needed.

```json
{
  "offsets": { "PK": -1, "IN": -1, "BD": -1 },
  "updatedAt": "<server timestamp>",
  "updatedBy": "<admin email>"
}
```

- Keys are ISO 3166-1 alpha-2 codes (upper case), values are whole days from −2 to 2.
- A country that is missing from `offsets` falls back to the built-in default.
- **Optional, later:** month-keyed overrides such as `"months": { "1448-07": { "PK": 0 } }`.
  These would keep past dates correct when a reader pages back across months. Skip them
  at first; one current value per country covers what readers see today.

### App (`khushidua`)

- Add a model `HijriAdjustment` in `lib/models/` with `fromMap` that ignores bad values.
  Clamp to `kMinHijriOffset`..`kMaxHijriOffset`.
- Add a controller that follows the document the same way
  `lib/controllers/donationController.dart` follows `SystemConfiguration/Donations`.
  That means a snapshot listener with `onError`. Firestore's offline cache provides the
  last known values at launch.
- Change `PrayerSettingsController.hijriOffset` so that, when the choice is "Automatic",
  it uses `adminOffsets[countryCode] ?? defaultHijriOffset(countryCode)`. Call `update()`
  when the document changes, so the prayer screen and the settings preview rebuild. The
  prayer screen already rebuilds on any settings change (`_onSettingsChanged`).
- Register the controller in `lib/controllers/initController.dart`.
- Tests: precedence, clamping, and a missing or malformed document. Put them next to
  `test/hijriDate_test.dart`.

### Admin panel (`khushiduaadmin`)

- Add a card to the **App controls** tab (`lib/views/tabs/appControls.dart`) titled
  "Islamic date", next to "Practice button" and "Donation prompts".
- Show one row per listed country (start with PK, IN, BD), each with a −2 … +2 selector.
  Add a live preview, "Today in Pakistan: 15 Jumada al-Awwal 1448", using the same
  `hijri` package. Add buttons to add or remove a country.
- Record each change with `AuditService.record(...)`, the way
  `lib/controllers/donationController.dart` does. That way History shows who moved the
  date and when.
- Add a note under the card: "Update after the moon-sighting announcement. Readers who
  set their own adjustment are not affected."

### Effort

About half a day for the app plus admin, and tests. There is no migration: until the
document exists, phones behave exactly as they do now.
