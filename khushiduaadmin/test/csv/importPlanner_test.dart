import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/csv/csvCodec.dart';
import 'package:khushiduaadmin/csv/csvSchema.dart';
import 'package:khushiduaadmin/csv/importPlanner.dart';

void main() {
  final duas = kCsvSchemas[CsvDataset.duas]!;
  final existing = <String, Map<String, dynamic>>{
    'd1': {
      'english': 'O Allah',
      'urdu': 'اے اللہ',
      'order': 1,
      'isEnabled': true,
      'subCategoryIds': ['s1'],
    },
  };

  ImportPlan plan(List<String> headers, List<List<String>> rows,
          {CsvSchema? schema,
          Map<String, Map<String, dynamic>>? current,
          Set<String> categories = const {},
          Set<String> subCategories = const {}}) =>
      planImport(
        schema: schema ?? duas,
        table: CsvTable(headers, rows),
        existing: current ?? existing,
        knownCategoryIds: categories,
        knownSubCategoryIds: subCategories,
      );

  group('updates', () {
    test('a row matching the database is unchanged and nothing applies', () {
      final result = plan(['id', 'english', 'urdu'], [
        ['d1', 'O Allah', 'اے اللہ']
      ]);
      expect(result.rows.single.status, RowStatus.unchanged);
      expect(result.canApply, isFalse);
    });

    test('only fields that differ are written', () {
      final result = plan(['id', 'english', 'urdu'], [
        ['d1', 'O Allah', 'نیا ترجمہ']
      ]);
      expect(result.rows.single.status, RowStatus.update);
      expect(result.rows.single.changes, {'urdu': 'نیا ترجمہ'});
      expect(result.canApply, isTrue);
    });

    test('columns missing from the file are left untouched', () {
      final result = plan(['id', 'Urdu'], [
        ['d1', 'نیا']
      ]);
      expect(result.rows.single.changes.keys, ['urdu']);
    });

    test('an update may not blank a required field', () {
      final result = plan(['id', 'english'], [
        ['d1', '']
      ]);
      expect(result.rows.single.status, RowStatus.invalid);
      expect(result.rows.single.errors.single, contains("can't be blank"));
    });
  });

  group('creates', () {
    test('a blank id creates a record with defaults', () {
      final row = plan(['id', 'english'], [
        ['', 'New dua']
      ]).rows.single;
      expect(row.status, RowStatus.create);
      expect(row.id, '');
      expect(row.changes, containsPair('english', 'New dua'));
      expect(row.changes, containsPair('isEnabled', true));
      expect(row.changes, containsPair('order', 0));
    });

    test('an unknown id creates that id, so a backup can restore records', () {
      final row = plan(['id', 'english'], [
        ['restored1', 'Back again']
      ]).rows.single;
      expect(row.status, RowStatus.create);
      expect(row.id, 'restored1');
    });

    test('new records need every required value', () {
      final row = plan(['id', 'urdu'], [
        ['', 'اردو']
      ]).rows.single;
      expect(row.status, RowStatus.invalid);
      expect(row.errors.single, contains('"english"'));
    });
  });

  group('whole-file rules', () {
    test('duplicate ids invalidate every copy', () {
      final result = plan(['id', 'english'], [
        ['d1', 'A'],
        ['d1', 'B'],
      ]);
      expect(result.rows.map((r) => r.status),
          everyElement(RowStatus.invalid));
      expect(result.rows.first.errors.single, contains('rows 2, 3'));
    });

    test('header problems stop the import before any row is read', () {
      final result = plan(['id', 'colour'], [
        ['d1', 'red']
      ]);
      expect(result.fileErrors, isNotEmpty);
      expect(result.rows, isEmpty);
      expect(result.canApply, isFalse);
    });

    test('export-only datasets refuse to import', () {
      final result = plan(['id', 'email'], [
        ['u1', 'a@b.co']
      ], schema: kCsvSchemas[CsvDataset.users]);
      expect(result.fileErrors.single, contains('exported but not imported'));
    });

    test('a header with no rows is reported', () {
      expect(plan(['id', 'english'], []).fileErrors.single,
          contains('no data rows'));
    });

    test('any invalid row blocks applying the valid ones', () {
      final result = plan(['id', 'english', 'order'], [
        ['d1', 'O Allah', '5'],
        ['d2', 'Other', 'five'],
      ]);
      expect(result.count(RowStatus.update), 1);
      expect(result.count(RowStatus.invalid), 1);
      expect(result.canApply, isFalse);
    });
  });

  group('references', () {
    test('unknown subcategory ids warn but do not block', () {
      final row = plan(['id', 'subCategoryIds'], [
        ['d1', 's1|s9']
      ], subCategories: {'s1'}).rows.single;
      expect(row.status, RowStatus.update);
      expect(row.warnings.single, contains('s9'));
    });

    test('a subcategory pointing at a missing category is an error', () {
      final row = plan(['id', 'english', 'categoryId'], [
        ['', 'Morning', 'nope']
      ],
              schema: kCsvSchemas[CsvDataset.subCategories],
              current: {},
              categories: {'c1'})
          .rows
          .single;
      expect(row.status, RowStatus.invalid);
      expect(row.errors.single, contains('nope'));
    });
  });

  group('home banner', () {
    final banner = kCsvSchemas[CsvDataset.homeBanner]!;

    test('imports as the single HomeBanner record', () {
      final row = plan(['id', 'title.English'], [
        ['', 'Welcome']
      ], schema: banner, current: {})
          .rows
          .single;
      expect(row.status, RowStatus.create);
      expect(row.id, 'HomeBanner');
    });

    test('rejects more than one row', () {
      final result = plan(['id', 'title.English'], [
        ['', 'A'],
        ['', 'B'],
      ], schema: banner, current: {});
      expect(result.fileErrors.single, contains('exactly one'));
    });
  });

  test('a blank notification recipient matches a stored null', () {
    final notifications = kCsvSchemas[CsvDataset.notifications]!;
    final result = plan(['id', 'title', 'message', 'sentTo'], [
      ['n1', 'Eid Mubarak', 'From all of us', '']
    ], schema: notifications, current: {
      'n1': {'title': 'Eid Mubarak', 'message': 'From all of us', 'sentTo': null},
    });
    expect(result.rows.single.status, RowStatus.unchanged);
  });

  test('exporting then importing the same data changes nothing', () {
    final doc = <String, dynamic>{
      'english': 'O Allah, "forgive" me\nplease',
      'arabic': 'اَللّٰھُمَّ اِنَّکَ عَفُوٌّ',
      'urdu': 'اے اللہ',
      'order': 2,
      'isEnabled': true,
      'littleKids': false,
      'subCategoryIds': ['s1', 's2'],
      'benefits': '=looks like a formula',
      'createdAt': DateTime.utc(2026, 1, 1),
    };
    final csv = encodeCsv(duas.headers, [exportRow(duas, 'd1', doc)]);
    final result = planImport(
      schema: duas,
      table: decodeCsv(csv),
      existing: {'d1': doc},
      knownSubCategoryIds: {'s1', 's2'},
    );
    final row = result.rows.single;
    expect(result.fileErrors, isEmpty);
    expect(row.status, RowStatus.unchanged,
        reason: 'changes: ${row.changes} errors: ${row.errors}');
  });

  test('nestDottedFields builds nested maps for Firestore merge writes', () {
    expect(
      nestDottedFields(
          {'title.Urdu': 'x', 'title.English': 'y', 'isEnabled': true}),
      {
        'title': {'Urdu': 'x', 'English': 'y'},
        'isEnabled': true,
      },
    );
  });
}
