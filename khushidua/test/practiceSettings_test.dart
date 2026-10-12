import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/models/practiceSettings.dart';

void main() {
  test('a missing document leaves Practice on, on the shipped server', () {
    final settings = PracticeSettings.fromMap(null);
    expect(settings.enabled, isTrue);
    expect(settings.url, PracticeSettings.fallbackUrl);
  });

  test('the document from before the switch keeps Practice on', () {
    final settings = PracticeSettings.fromMap({'URL': 'https://ml.example/'});
    expect(settings.enabled, isTrue);
    expect(settings.url, 'https://ml.example/');
  });

  test('the admin switch greys Practice out', () {
    final settings = PracticeSettings.fromMap({
      'URL': 'https://ml.example/',
      'practiceEnabled': false,
    });
    expect(settings.enabled, isFalse);
  });

  test('a blank URL falls back to the shipped server', () {
    final settings = PracticeSettings.fromMap({'URL': '  '});
    expect(settings.url, PracticeSettings.fallbackUrl);
  });
}
