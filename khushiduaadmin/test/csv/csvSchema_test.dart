import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/csv/csvSchema.dart';

CsvColumn column(CsvDataset dataset, String field) =>
    kCsvSchemas[dataset]!.columns.firstWhere((c) => c.field == field);

void main() {
  group('schemas', () {
    test('every dataset starts with id and has unique headers', () {
      for (final schema in kCsvSchemas.values) {
        expect(schema.headers.first, 'id', reason: schema.label);
        expect(schema.headers.toSet().length, schema.headers.length,
            reason: schema.label);
      }
    });

    test('duas use the database spellings for all 21 languages', () {
      final headers = kCsvSchemas[CsvDataset.duas]!.headers;
      expect(
          headers,
          containsAll([
            'english', 'arabic', 'urdu', 'sindhi', //
            'gujrati', 'mandrain', 'portugese', 'telgu',
          ]));
      expect(headers.where((h) => kLanguageFields.any((l) => l.$1 == h)),
          hasLength(21));
    });

    test('users and admins are export-only; content is importable', () {
      expect(kCsvSchemas[CsvDataset.users]!.importable, isFalse);
      expect(kCsvSchemas[CsvDataset.admins]!.importable, isFalse);
      for (final d in [
        CsvDataset.duas,
        CsvDataset.categories,
        CsvDataset.subCategories,
        CsvDataset.homeBanner,
        CsvDataset.notifications,
      ]) {
        expect(kCsvSchemas[d]!.importable, isTrue, reason: d.name);
      }
    });

    test('the user export never includes device tokens', () {
      expect(kCsvSchemas[CsvDataset.users]!.headers,
          isNot(contains('fcmToken')));
    });
  });

  group('matchesHeader', () {
    test('accepts the database spelling, the real spelling and any case', () {
      final gujrati = column(CsvDataset.duas, 'gujrati');
      for (final header in ['gujrati', 'Gujarati', ' GUJARATI ']) {
        expect(gujrati.matchesHeader(header), isTrue, reason: header);
      }
      expect(column(CsvDataset.duas, 'telgu').matchesHeader('Telugu'), isTrue);
    });
  });

  group('exportRow', () {
    test('formats every column type', () {
      final schema = kCsvSchemas[CsvDataset.duas]!;
      final row = exportRow(schema, 'd1', {
        'english': 'O Allah',
        'isEnabled': true,
        'olderKids': false,
        'order': 3,
        'subCategoryIds': ['s1', 's2'],
        'createdAt': DateTime.utc(2026, 9, 14, 10),
      });
      String cell(String field) => row[schema.headers.indexOf(field)];

      expect(row.first, 'd1');
      expect(cell('english'), 'O Allah');
      expect(cell('isEnabled'), 'TRUE');
      expect(cell('olderKids'), 'FALSE');
      expect(cell('order'), '3');
      expect(cell('subCategoryIds'), 's1|s2');
      expect(cell('createdAt'), '2026-09-14T10:00:00.000Z');
      expect(cell('urdu'), '');
      expect(cell('grownUps'), '');
    });

    test('reads nested banner fields by dotted path', () {
      final schema = kCsvSchemas[CsvDataset.homeBanner]!;
      final row = exportRow(schema, 'HomeBanner', {
        'title': {'Urdu': 'خوش آمدید'},
      });
      expect(row[schema.headers.indexOf('title.Urdu')], 'خوش آمدید');
    });
  });

  group('parseCell', () {
    test('booleans accept Excel TRUE/FALSE and common variants', () {
      final c = column(CsvDataset.duas, 'isEnabled');
      for (final raw in ['TRUE', 'true', 'yes', '1']) {
        expect(parseCell(c, raw).value, isTrue, reason: raw);
      }
      for (final raw in ['FALSE', 'no', '0']) {
        expect(parseCell(c, raw).value, isFalse, reason: raw);
      }
      expect(parseCell(c, '').skip, isTrue);
      expect(parseCell(c, 'maybe').error, contains('TRUE or FALSE'));
    });

    test('integers accept Excel-style "3.0" but not fractions or words', () {
      final c = column(CsvDataset.duas, 'order');
      expect(parseCell(c, '3').value, 3);
      expect(parseCell(c, '3.0').value, 3);
      expect(parseCell(c, '').skip, isTrue);
      expect(parseCell(c, '3.5').error, contains('whole number'));
      expect(parseCell(c, 'three').error, contains('whole number'));
    });

    test('lists split on | and drop blanks', () {
      final c = column(CsvDataset.duas, 'subCategoryIds');
      expect(parseCell(c, ' s1 | |s2 ').value, ['s1', 's2']);
      expect(parseCell(c, '').value, <String>[]);
    });

    test('text is trimmed', () {
      expect(parseCell(column(CsvDataset.duas, 'english'), '  hi ').value,
          'hi');
    });

    test('flags language text destroyed by saving as plain CSV', () {
      final urdu = column(CsvDataset.duas, 'urdu');
      expect(parseCell(urdu, '???? ???').error, contains('CSV UTF-8'));
      expect(parseCell(urdu, '?').error, isNull);
      expect(
          parseCell(column(CsvDataset.duas, 'english'), 'Why?').value, 'Why?');
    });

    test('a blank notification recipient becomes null, meaning everyone', () {
      final result = parseCell(column(CsvDataset.notifications, 'sentTo'), '');
      expect(result.skip, isFalse);
      expect(result.value, isNull);
    });

    test('timestamps are never imported', () {
      expect(
          parseCell(column(CsvDataset.duas, 'createdAt'), '2026-01-01').skip,
          isTrue);
    });
  });

  group('mapHeaders', () {
    final duas = kCsvSchemas[CsvDataset.duas]!;

    test('maps headers by name, alias and position', () {
      final mapping = mapHeaders(duas, ['Urdu', 'id', 'english']);
      expect(mapping.errors, isEmpty);
      expect(mapping.idIndex, 1);
      expect(mapping.columnIndexes[column(CsvDataset.duas, 'urdu')], 0);
    });

    test('requires an id column', () {
      expect(mapHeaders(duas, ['english']).errors.single, contains('"id"'));
    });

    test('rejects unknown columns', () {
      expect(mapHeaders(duas, ['id', 'colour']).errors.single,
          contains('Unknown column "colour"'));
    });

    test('rejects two headers for the same field', () {
      expect(mapHeaders(duas, ['id', 'gujrati', 'Gujarati']).errors.single,
          contains('gujrati'));
    });

    test('ignores blank header cells', () {
      expect(mapHeaders(duas, ['id', '', 'english']).errors, isEmpty);
    });
  });
}
