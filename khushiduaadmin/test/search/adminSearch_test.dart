import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/models/categoryModel.dart';
import 'package:khushiduaadmin/models/duaModel.dart';
import 'package:khushiduaadmin/models/notificationModel.dart';
import 'package:khushiduaadmin/models/subCategoryModel.dart';
import 'package:khushiduaadmin/models/userModel.dart';
import 'package:khushiduaadmin/search/adminSearch.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases, trims and collapses whitespace', () {
      expect(normalizeForSearch('  Morning   DUA\n'), 'morning dua');
    });

    test('strips Arabic diacritics and tatweel', () {
      expect(normalizeForSearch('اَللّٰھُمَّ'), normalizeForSearch('اللهم'));
      expect(normalizeForSearch('بـــسم'), 'بسم');
    });

    test('treats Arabic and Urdu letter variants as the same letter', () {
      expect(normalizeForSearch('أإآٱا'), 'ااااا');
      expect(normalizeForSearch('کی'), normalizeForSearch('كي'));
      expect(normalizeForSearch('ہھ'), normalizeForSearch('هه'));
      expect(normalizeForSearch('ى'), normalizeForSearch('ي'));
    });

    test('leaves Latin accents alone', () {
      expect(normalizeForSearch('Français'), 'français');
    });
  });

  group('matchesQuery', () {
    test('hasSearchText ignores whitespace and lone diacritics', () {
      expect(hasSearchText('  \n'), isFalse);
      expect(hasSearchText('َ'), isFalse);
      expect(hasSearchText(' a '), isTrue);
    });

    test('an empty query matches everything', () {
      expect(matchesQuery('', ['anything']), isTrue);
      expect(matchesQuery('   ', const []), isTrue);
    });

    test('matches a substring in any field', () {
      expect(matchesQuery('forgive', ['id1', 'O Allah, forgive me']), isTrue);
      expect(matchesQuery('mercy', ['id1', 'O Allah, forgive me']), isFalse);
    });

    test('every word must match, but in any field and any order', () {
      final fields = ['Morning remembrance', 'صبح کی دعا'];
      expect(matchesQuery('remembrance morning', fields), isTrue);
      expect(matchesQuery('morning دعا', fields), isTrue);
      expect(matchesQuery('morning evening', fields), isFalse);
    });

    test('ignores null fields', () {
      expect(matchesQuery('x', [null, 'x']), isTrue);
      expect(matchesQuery('x', [null]), isFalse);
    });

    test('Arabic without harakat finds text written with them', () {
      expect(matchesQuery('اللهم', ['اَللّٰھُمَّ اِنَّکَ عَفُوٌّ']), isTrue);
    });
  });

  group('filterBySearch', () {
    test('keeps the original order and returns the same list when blank', () {
      final items = ['beta', 'alpha', 'alphabet'];
      expect(filterBySearch(items, 'alpha', (s) => [s]), ['alpha', 'alphabet']);
      expect(identical(filterBySearch(items, ' ', (s) => [s]), items), isTrue);
    });
  });

  group('model fields', () {
    test('duas are found by id, any language, transliteration and benefits',
        () {
      final dua = DuaModel.fromMap({
        'id': '0tgKka3QG4SmpwiCyVfV',
        'english': 'Before sleeping',
        'urdu': 'سونے سے پہلے',
        'spanish': 'Antes de dormir',
        'transliteration': 'Bismika Allahumma',
        'benefits': 'Protection through the night',
        'description': 'Recited in bed',
        'subCategoryIds': <String>[],
      });
      final fields = duaSearchFields(dua);
      for (final query in [
        '0tgKka',
        'sleeping',
        'سونے',
        'dormir',
        'bismika',
        'protection',
        'in bed',
      ]) {
        expect(matchesQuery(query, fields), isTrue, reason: query);
      }
    });

    test('categories and subcategories are found by id and any language', () {
      final category = CategoryModel.fromMap({
        'id': 'cat1',
        'english': 'Daily life',
        'turkish': 'Günlük',
      });
      expect(matchesQuery('günlük', categorySearchFields(category)), isTrue);
      expect(matchesQuery('cat1', categorySearchFields(category)), isTrue);

      final sub = SubCategoryModel.fromMap({
        'id': 'sub1',
        'english': 'Eating',
        'hindi': 'भोजन',
        'categoryId': 'cat1',
        'image': '',
      });
      expect(matchesQuery('भोजन', subCategorySearchFields(sub)), isTrue);
      expect(matchesQuery('sub1', subCategorySearchFields(sub)), isTrue);
    });

    test('users are found by name, email and id', () {
      final at = Timestamp.fromDate(DateTime.utc(2026));
      final user = UserModel.fromMap({
        'id': 'u42',
        'name': 'Sara Khan',
        'email': 'sara@example.com',
        'points': 0,
        'fcmToken': 'secret-token',
        'isLoggedIn': false,
        'isMember': false,
        'isBlocked': false,
        'readDuas': <String>[],
        'createdAt': at,
        'updatedAt': at,
      });
      final fields = userSearchFields(user);
      expect(matchesQuery('khan', fields), isTrue);
      expect(matchesQuery('example.com', fields), isTrue);
      expect(matchesQuery('u42', fields), isTrue);
      expect(matchesQuery('secret', fields), isFalse,
          reason: 'device tokens are not searchable');
    });

    test('notifications are found by title and message', () {
      final notification = NotificationModel.fromMap({
        'id': 'n1',
        'title': 'Eid Mubarak',
        'message': 'From all of us',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026)),
      });
      final fields = notificationSearchFields(notification);
      expect(matchesQuery('eid', fields), isTrue);
      expect(matchesQuery('all of us', fields), isTrue);
    });
  });
}
