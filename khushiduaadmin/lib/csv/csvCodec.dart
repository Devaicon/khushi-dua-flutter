/// RFC 4180 CSV reading and writing, tuned for files that round-trip through
/// Microsoft Excel.
///
/// Dependency-free and free of `dart:html`, so it runs under `flutter test`.
library;

import 'dart:convert';

const String _bom = '﻿';

/// First characters that make a spreadsheet treat a cell as a formula.
const Set<String> _formulaTriggers = {'=', '+', '-', '@', '\t', '\r'};

class CsvTable {
  const CsvTable(this.headers, this.rows);

  final List<String> headers;

  /// Every row has exactly `headers.length` cells.
  final List<List<String>> rows;
}

class CsvFormatException implements Exception {
  const CsvFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Neutralises a cell a spreadsheet would execute as a formula by prefixing
/// an apostrophe. Protects whoever opens an export from injected formulas.
String guardFormula(String value) {
  if (value.isEmpty) return value;
  return _formulaTriggers.contains(value[0]) ? "'$value" : value;
}

/// Reverses [guardFormula]. Only strips an apostrophe that precedes a trigger
/// character, so text that genuinely starts with an apostrophe survives.
String unguardFormula(String value) {
  if (value.length >= 2 &&
      value[0] == "'" &&
      _formulaTriggers.contains(value[1])) {
    return value.substring(1);
  }
  return value;
}

/// Encodes a table as CSV with a UTF-8 byte order mark and CRLF line endings,
/// which is what Excel expects for non-Latin text.
String encodeCsv(List<String> headers, List<List<String>> rows) {
  final buffer = StringBuffer(_bom);
  void writeRecord(List<String> cells) {
    buffer
      ..write(cells.map((cell) => _quote(guardFormula(cell))).join(','))
      ..write('\r\n');
  }

  writeRecord(headers);
  for (final row in rows) {
    writeRecord(row);
  }
  return buffer.toString();
}

String _quote(String cell) {
  const specials = [',', '"', '\n', '\r', ';'];
  if (!specials.any(cell.contains)) return cell;
  return '"${cell.replaceAll('"', '""')}"';
}

/// Decodes raw file bytes, refusing anything that isn't valid UTF-8.
CsvTable decodeCsvBytes(List<int> bytes) {
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const CsvFormatException(
        "This file isn't saved as UTF-8, so Arabic, Urdu and other scripts "
        "would be corrupted. In Excel choose File → Save As → "
        "\"CSV UTF-8 (Comma delimited)\" and import that file.");
  }
  return decodeCsv(text);
}

CsvTable decodeCsv(String text) {
  final input = text.startsWith(_bom) ? text.substring(1) : text;
  if (input.trim().isEmpty) {
    throw const CsvFormatException('The file is empty.');
  }

  final records = _parse(input, _detectDelimiter(input))
    ..removeWhere((record) => record.every((cell) => cell.trim().isEmpty));
  if (records.isEmpty) {
    throw const CsvFormatException('The file is empty.');
  }

  final headers = [for (final h in records.first) unguardFormula(h).trim()];
  final width = headers.length;
  final rows = <List<String>>[];

  for (var i = 1; i < records.length; i++) {
    final cells = [
      for (final cell in records[i])
        unguardFormula(cell.replaceAll('\r\n', '\n')),
    ];
    if (cells.length > width) {
      if (cells.sublist(width).any((cell) => cell.trim().isNotEmpty)) {
        // Record i is spreadsheet row i + 1, because the header is row 1.
        throw CsvFormatException(
            'Row ${i + 1} has ${cells.length} cells but the header has '
            '$width. A cell probably contains an unquoted comma.');
      }
      cells.removeRange(width, cells.length);
    }
    while (cells.length < width) {
      cells.add('');
    }
    rows.add(cells);
  }

  return CsvTable(headers, rows);
}

/// Excel in many European locales saves with semicolons.
String _detectDelimiter(String input) {
  final end = input.indexOf('\n');
  final firstLine = end == -1 ? input : input.substring(0, end);
  final commas = ','.allMatches(firstLine).length;
  final semicolons = ';'.allMatches(firstLine).length;
  return semicolons > commas ? ';' : ',';
}

List<List<String>> _parse(String input, String delimiter) {
  final records = <List<String>>[];
  var record = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  while (i < input.length) {
    final ch = input[i];

    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(ch);
      i++;
      continue;
    }

    if (ch == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (ch == delimiter) {
      record.add(field.toString());
      field.clear();
    } else if (ch == '\r' || ch == '\n') {
      record.add(field.toString());
      field.clear();
      records.add(record);
      record = <String>[];
      if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
    } else {
      field.write(ch);
    }
    i++;
  }

  if (inQuotes) {
    throw const CsvFormatException(
        'The file ends inside a quoted cell, so it may be cut off.');
  }
  if (field.isNotEmpty || record.isNotEmpty) {
    record.add(field.toString());
    records.add(record);
  }
  return records;
}
