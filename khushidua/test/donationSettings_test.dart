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

  test('card text keeps filled-in strings and drops the rest', () {
    final s = DonationSettings.fromMap({
      'cardMessage': {'Urdu': ' آپ کا عطیہ ', 'English': '  ', 'French': 3},
      'cardTitle': 'not a map',
    });
    expect(s.cardMessage, {'Urdu': 'آپ کا عطیہ'});
    expect(s.cardTitle, isEmpty);
  });

  test('card text survives a round trip', () {
    const s = DonationSettings(cardTitle: {'English': 'Help us'});
    expect(DonationSettings.fromMap(s.toMap()).cardTitle, {'English': 'Help us'});
  });
}
