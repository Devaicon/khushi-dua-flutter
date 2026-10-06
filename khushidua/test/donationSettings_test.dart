import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/models/donationSettings.dart';

void main() {
  test('with no document every placement is shown', () {
    final s = DonationSettings.fromMap(null);
    for (final key in DonationSettings.placements.keys) {
      expect(s.shows(key), isTrue, reason: key);
    }
  });

  test('a placement switched off is hidden; the rest stay shown', () {
    final s = DonationSettings.fromMap({'search': false});
    expect(s.search, isFalse);
    expect(s.home, isTrue);
    expect(s.reminder, isTrue);
  });

  test('the master switch hides everything but keeps each switch', () {
    final s = DonationSettings.fromMap({'enabled': false, 'home': true});
    expect(s.home, isFalse);
    expect(s.isOn('home'), isTrue);
  });

  test('values of the wrong type fall back to shown', () {
    final s = DonationSettings.fromMap({'enabled': 'no', 'prayer': 0});
    expect(s.enabled, isTrue);
    expect(s.prayer, isTrue);
  });
}
