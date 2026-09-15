import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/csv/csvCodec.dart';

void main() {
  group('encodeCsv', () {
    test('starts with a UTF-8 byte order mark so Excel reads Arabic correctly',
        () {
      final csv = encodeCsv(['id'], [
        ['1']
      ]);
      expect(csv.codeUnitAt(0), 0xFEFF);
      expect(utf8.encode(csv).take(3), [0xEF, 0xBB, 0xBF]);
    });

    test('uses CRLF line endings', () {
      expect(
          encodeCsv(['a'], [
            ['1']
          ]),
          '﻿a\r\n1\r\n');
    });

    test('quotes cells containing commas, quotes and newlines', () {
      expect(
          encodeCsv(['text'], [
            ['a, "b"\nc']
          ]),
          '﻿text\r\n"a, ""b""\nc"\r\n');
    });
  });

  group('formula guard', () {
    test('prefixes an apostrophe on cells a spreadsheet would execute', () {
      for (final value in ['=1+1', '+1', '-1', '@A1', '\t=1']) {
        expect(guardFormula(value), "'$value");
      }
    });

    test('leaves ordinary text alone', () {
      for (final value in ['', 'Allahumma', 'اَللّٰھُمَّ', "'quoted", '1-2']) {
        expect(guardFormula(value), value);
      }
    });

    test('unguard reverses guard', () {
      for (final value in ['=1+1', '-1', "'quoted", "'", 'plain', '']) {
        expect(unguardFormula(guardFormula(value)), value);
      }
    });
  });

  group('decodeCsv', () {
    test('round-trips Arabic, commas, quotes, newlines and formula text', () {
      const rows = [
        [
          '0tgKka3QG4SmpwiCyVfV',
          'اَللّٰھُمَّ اِنَّکَ عَفُوٌّ',
          'O Allah, "forgive" me\nplease',
          '=not a formula',
        ]
      ];
      final table =
          decodeCsv(encodeCsv(['id', 'arabic', 'english', 'note'], rows));
      expect(table.headers, ['id', 'arabic', 'english', 'note']);
      expect(table.rows, rows);
    });

    test('strips the byte order mark from the first header', () {
      expect(decodeCsv('﻿id,english\r\n1,a\r\n').headers.first, 'id');
    });

    test('accepts semicolon-separated files from European Excel', () {
      expect(decodeCsv('id;english\n1;Hello, world\n').rows, [
        ['1', 'Hello, world']
      ]);
    });

    test('accepts LF, CRLF and a missing final newline', () {
      expect(decodeCsv('id,a\n1,x').rows, [
        ['1', 'x']
      ]);
      expect(decodeCsv('id,a\r\n1,x\r\n').rows, [
        ['1', 'x']
      ]);
    });

    test('normalises CRLF inside quoted cells to LF', () {
      expect(decodeCsv('id,a\r\n1,"x\r\ny"\r\n').rows.single[1], 'x\ny');
    });

    test('ignores the blank trailing lines Excel adds', () {
      expect(decodeCsv('id,a\n1,x\n,\n\n').rows.length, 1);
    });

    test('pads short rows', () {
      expect(decodeCsv('id,a,b\n1,x\n').rows.single, ['1', 'x', '']);
    });

    test('drops empty cells beyond the header', () {
      expect(decodeCsv('id,a\n1,x,,\n').rows.single, ['1', 'x']);
    });

    test('rejects rows with data beyond the header', () {
      expect(() => decodeCsv('id,a\n1,x,y\n'),
          throwsA(isA<CsvFormatException>()));
    });

    test('rejects an unterminated quote', () {
      expect(() => decodeCsv('id,a\n1,"x\n'),
          throwsA(isA<CsvFormatException>()));
    });

    test('rejects an empty file', () {
      expect(() => decodeCsv('﻿  '), throwsA(isA<CsvFormatException>()));
    });
  });

  group('decodeCsvBytes', () {
    test('decodes UTF-8', () {
      expect(decodeCsvBytes(utf8.encode('id,urdu\n1,اردو\n')).rows.single[1],
          'اردو');
    });

    test('explains how to fix a file that is not UTF-8', () {
      // "id\n" followed by a lone 0xE9 byte, which is invalid UTF-8.
      const bytes = [0x69, 0x64, 0x0A, 0xE9, 0x0A];
      expect(
        () => decodeCsvBytes(bytes),
        throwsA(isA<CsvFormatException>()
            .having((e) => e.message, 'message', contains('CSV UTF-8'))),
      );
    });
  });
}
