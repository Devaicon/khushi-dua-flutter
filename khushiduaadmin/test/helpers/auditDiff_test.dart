import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/helpers/auditDiff.dart';

void main() {
  group('changedFields', () {
    test('lists only the fields that differ, ignoring bookkeeping', () {
      expect(
        changedFields(
          {'english': 'a', 'urdu': 'b', 'updatedAt': 1, 'order': 2},
          {'english': 'a', 'urdu': 'c', 'updatedAt': 9, 'order': 3},
        ),
        ['order', 'urdu'],
      );
    });

    test('treats null, empty and missing as the same', () {
      expect(
        changedFields(
          {'englishTranslation': null, 'description': ''},
          {'englishTranslation': ''},
        ),
        isEmpty,
      );
    });

    test('compares lists by content', () {
      expect(
        changedFields({'subCategoryIds': ['a', 'b']},
            {'subCategoryIds': ['a', 'b']}),
        isEmpty,
      );
      expect(
        changedFields({'subCategoryIds': ['a']},
            {'subCategoryIds': ['a', 'b']}),
        ['subCategoryIds'],
      );
    });

    test('a created document changes every filled field', () {
      expect(changedFields(null, {'english': 'x', 'urdu': ''}), ['english']);
    });
  });

  group('describeFields', () {
    test('names a few fields and counts the rest', () {
      expect(describeFields(['english']), 'English');
      expect(describeFields(['english', 'englishTranslation']),
          'English and English audio');
      expect(describeFields(['a', 'b', 'c', 'd', 'e']), 'A, B, C and 2 more');
    });
  });
}
