/// Where the app asks for donations, stored at
/// `SystemConfiguration/Donations`.
///
/// Kept identical to the app's copy (khushidua/lib/models). Every place
/// defaults to shown: a missing document, a missing field, or a
/// phone that has never been online all behave as the app did before the
/// switches existed. [enabled] turns them all off at once.
class DonationSettings {
  static const String docId = 'Donations';

  /// Field name → what it controls, in the order the admin panel lists them.
  static const Map<String, String> placements = {
    'home': 'Home screen card',
    'search': 'Search screen card',
    'searchPill': 'Search screen Donate pill',
    'prayer': 'Prayer Times screen card',
    'settings': 'Donate row in Settings',
    'reminder': 'Weekly support reminder',
  };

  const DonationSettings({this.enabled = true, this.shown = const {}});

  /// The master switch.
  final bool enabled;

  /// Per-placement switches; a placement not listed here is shown.
  final Map<String, bool> shown;

  factory DonationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DonationSettings();
    return DonationSettings(
      enabled: map['enabled'] is bool ? map['enabled'] as bool : true,
      shown: {
        for (final key in placements.keys)
          if (map[key] is bool) key: map[key] as bool,
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    for (final key in placements.keys) key: isOn(key),
  };

  /// The placement's own switch, ignoring the master switch.
  bool isOn(String placement) => shown[placement] ?? true;

  /// Whether the app shows [placement]: the master switch and its own.
  bool shows(String placement) => enabled && isOn(placement);

  bool get home => shows('home');
  bool get search => shows('search');
  bool get searchPill => shows('searchPill');
  bool get prayer => shows('prayer');
  bool get settings => shows('settings');
  bool get reminder => shows('reminder');
}
