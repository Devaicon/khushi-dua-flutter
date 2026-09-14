import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/models/homeBannerModel.dart';

void main() {
  group('fromMap', () {
    test('reads per-language title and subtitle', () {
      final banner = HomeBannerModel.fromMap({
        'isEnabled': true,
        'title': {'English': 'Hello', 'Arabic': 'مرحبا'},
        'subtitle': {'English': 'Sub', 'Arabic': 'فرعي'},
        'imageUrl': 'https://example.com/b.png',
        'linkCategoryId': 'cat123',
      });

      expect(banner.isEnabled, isTrue);
      expect(banner.titleFor('English'), 'Hello');
      expect(banner.titleFor('Arabic'), 'مرحبا');
      expect(banner.subtitleFor('Arabic'), 'فرعي');
      expect(banner.imageUrl, 'https://example.com/b.png');
      expect(banner.linkCategoryId, 'cat123');
    });

    test('tolerates a completely empty document', () {
      final banner = HomeBannerModel.fromMap({});
      expect(banner.isEnabled, isFalse);
      expect(banner.titleFor('English'), isEmpty);
      expect(banner.imageUrl, isEmpty);
      expect(banner.hasLink, isFalse);
    });

    test('tolerates non-map title values rather than throwing', () {
      final banner = HomeBannerModel.fromMap({'title': 'a plain string'});
      expect(banner.titleFor('English'), isEmpty);
    });
  });

  group('language fallback', () {
    final banner = HomeBannerModel.fromMap({
      'title': {'English': 'Hello', 'Urdu': ''},
      'subtitle': {'English': 'Sub'},
    });

    test('falls back to English when the language is missing', () {
      expect(banner.titleFor('Tamil'), 'Hello');
      expect(banner.subtitleFor('Tamil'), 'Sub');
    });

    test('falls back to English when the language is present but blank', () {
      expect(banner.titleFor('Urdu'), 'Hello');
    });

    test('returns empty when English is missing too', () {
      final bare = HomeBannerModel.fromMap({
        'title': {'Arabic': 'مرحبا'},
      });
      expect(bare.titleFor('Tamil'), isEmpty);
    });
  });

  group('hasContent', () {
    test('false when disabled even with text', () {
      final banner = HomeBannerModel.fromMap({
        'isEnabled': false,
        'title': {'English': 'Hello'},
      });
      expect(banner.hasContent('English'), isFalse);
    });

    test('true when enabled and the language resolves to text', () {
      final banner = HomeBannerModel.fromMap({
        'isEnabled': true,
        'title': {'English': 'Hello'},
      });
      expect(banner.hasContent('Tamil'), isTrue);
    });

    test('false when enabled but every field is blank', () {
      final banner = HomeBannerModel.fromMap({
        'isEnabled': true,
        'title': {'English': ''},
        'subtitle': {'English': ''},
      });
      expect(banner.hasContent('English'), isFalse);
    });

    test('true when only the subtitle has text', () {
      final banner = HomeBannerModel.fromMap({
        'isEnabled': true,
        'subtitle': {'English': 'Sub only'},
      });
      expect(banner.hasContent('English'), isTrue);
    });
  });

  test('toMap round-trips through fromMap', () {
    final original = HomeBannerModel.fromMap({
      'isEnabled': true,
      'title': {'English': 'Hello', 'Arabic': 'مرحبا'},
      'subtitle': {'English': 'Sub'},
      'imageUrl': 'https://example.com/b.png',
      'linkCategoryId': 'cat123',
    });

    final restored = HomeBannerModel.fromMap(original.toMap());
    expect(restored.isEnabled, original.isEnabled);
    expect(restored.titleFor('Arabic'), 'مرحبا');
    expect(restored.subtitleFor('English'), 'Sub');
    expect(restored.imageUrl, original.imageUrl);
    expect(restored.linkCategoryId, original.linkCategoryId);
  });
}
