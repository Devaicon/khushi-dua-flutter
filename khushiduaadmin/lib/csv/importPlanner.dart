/// Compares an uploaded CSV with the database and decides, row by row, what
/// an import would do — before anything is written.
library;

import 'csvCodec.dart';
import 'csvSchema.dart';

enum RowStatus { create, update, unchanged, invalid }

class PlannedRow {
  const PlannedRow({
    required this.rowNumber,
    required this.id,
    required this.status,
    required this.changes,
    required this.errors,
    required this.warnings,
  });

  /// Spreadsheet row number; the header is row 1.
  final int rowNumber;

  /// Empty for a new record whose id will be generated on write.
  final String id;
  final RowStatus status;

  /// Dotted field → value to write. Only fields that differ, for updates.
  final Map<String, Object?> changes;
  final List<String> errors;
  final List<String> warnings;
}

class ImportPlan {
  const ImportPlan({
    required this.schema,
    required this.fileErrors,
    required this.rows,
  });

  final CsvSchema schema;
  final List<String> fileErrors;
  final List<PlannedRow> rows;

  int count(RowStatus status) => rows.where((r) => r.status == status).length;

  int get writeCount => count(RowStatus.create) + count(RowStatus.update);

  /// All-or-nothing: one bad row blocks the import, so a half-applied file
  /// never leaves the data in a state nobody reviewed.
  bool get canApply =>
      fileErrors.isEmpty && count(RowStatus.invalid) == 0 && writeCount > 0;
}

ImportPlan planImport({
  required CsvSchema schema,
  required CsvTable table,
  required Map<String, Map<String, dynamic>> existing,
  Set<String> knownCategoryIds = const {},
  Set<String> knownSubCategoryIds = const {},
}) {
  ImportPlan fail(List<String> errors) =>
      ImportPlan(schema: schema, fileErrors: errors, rows: const []);

  if (!schema.importable) {
    return fail(['${schema.label} can be exported but not imported.']);
  }

  final mapping = mapHeaders(schema, table.headers);
  if (mapping.errors.isNotEmpty) return fail(mapping.errors);

  if (table.rows.isEmpty) {
    return fail(['The file has a header but no data rows.']);
  }
  if (schema.singleDocId != null && table.rows.length != 1) {
    return fail([
      '${schema.label} is a single record, so the file must have exactly one '
          'data row. It has ${table.rows.length}.'
    ]);
  }

  final rowNumbersById = <String, List<int>>{};
  for (var i = 0; i < table.rows.length; i++) {
    final id = table.rows[i][mapping.idIndex].trim();
    if (id.isNotEmpty) (rowNumbersById[id] ??= []).add(i + 2);
  }

  final planned = <PlannedRow>[];

  for (var i = 0; i < table.rows.length; i++) {
    final rowNumber = i + 2;
    final cells = table.rows[i];
    final errors = <String>[];
    final warnings = <String>[];

    var id = cells[mapping.idIndex].trim();
    if (schema.singleDocId != null) {
      if (id.isNotEmpty && id != schema.singleDocId) {
        errors.add('id must be "${schema.singleDocId}" or blank.');
      }
      id = schema.singleDocId!;
    } else if (id.isNotEmpty && rowNumbersById[id]!.length > 1) {
      errors.add(
          'id "$id" appears on rows ${rowNumbersById[id]!.join(', ')}.');
    }

    final values = <String, Object?>{};
    mapping.columnIndexes.forEach((column, index) {
      final result = parseCell(column, cells[index]);
      if (result.error != null) {
        errors.add(result.error!);
      } else if (!result.skip) {
        values[column.field] = result.value;
      }
    });

    final current = id.isEmpty ? null : existing[id];
    final isCreate = current == null;

    for (final column in schema.columns.where((c) => c.required)) {
      final present = mapping.columnIndexes.containsKey(column);
      final value = values[column.field];
      if (isCreate && (!present || value == null || value == '')) {
        errors.add('New records need a "${column.field}" value.');
      } else if (!isCreate && present && value == '') {
        errors.add('"${column.field}" can\'t be blank.');
      }
    }

    _checkReferences(schema.dataset, values, knownCategoryIds,
        knownSubCategoryIds, errors, warnings);

    if (errors.isNotEmpty) {
      planned.add(PlannedRow(
          rowNumber: rowNumber,
          id: id,
          status: RowStatus.invalid,
          changes: const {},
          errors: errors,
          warnings: warnings));
      continue;
    }

    if (isCreate) {
      planned.add(PlannedRow(
          rowNumber: rowNumber,
          id: id,
          status: RowStatus.create,
          changes: {
            for (final c in schema.columns)
              if (c.importable && c.defaultValue != null) c.field: c.defaultValue,
            ...values,
          },
          errors: const [],
          warnings: warnings));
      continue;
    }

    final changes = <String, Object?>{};
    values.forEach((field, value) {
      final column = schema.columns.firstWhere((c) => c.field == field);
      if (!_sameValue(column, valueAtPath(current, field), value)) {
        changes[field] = value;
      }
    });

    planned.add(PlannedRow(
        rowNumber: rowNumber,
        id: id,
        status: changes.isEmpty ? RowStatus.unchanged : RowStatus.update,
        changes: changes,
        errors: const [],
        warnings: warnings));
  }

  return ImportPlan(schema: schema, fileErrors: const [], rows: planned);
}

void _checkReferences(
  CsvDataset dataset,
  Map<String, Object?> values,
  Set<String> knownCategoryIds,
  Set<String> knownSubCategoryIds,
  List<String> errors,
  List<String> warnings,
) {
  switch (dataset) {
    case CsvDataset.duas:
      final ids = values['subCategoryIds'];
      if (ids is List && knownSubCategoryIds.isNotEmpty) {
        for (final id in ids) {
          if (!knownSubCategoryIds.contains(id)) {
            warnings.add('Subcategory "$id" doesn\'t exist, so the dua won\'t '
                'appear under it.');
          }
        }
      }
    case CsvDataset.subCategories:
      final categoryId = values['categoryId'];
      if (categoryId is String &&
          categoryId.isNotEmpty &&
          knownCategoryIds.isNotEmpty &&
          !knownCategoryIds.contains(categoryId)) {
        errors.add('Category "$categoryId" doesn\'t exist.');
      }
    case CsvDataset.homeBanner:
      final link = values['linkCategoryId'];
      if (link is String &&
          link.isNotEmpty &&
          knownCategoryIds.isNotEmpty &&
          !knownCategoryIds.contains(link)) {
        warnings.add('The banner links to category "$link", which doesn\'t '
            'exist, so tapping it will do nothing.');
      }
    case CsvDataset.categories:
    case CsvDataset.notifications:
    case CsvDataset.users:
    case CsvDataset.admins:
      break;
  }
}

bool _sameValue(CsvColumn column, Object? current, Object? incoming) {
  switch (column.type) {
    case CsvColumnType.text:
      final stored = (current?.toString() ?? '').replaceAll('\r\n', '\n');
      return stored.trim() == ((incoming as String?) ?? '');
    case CsvColumnType.boolean:
      return current == incoming;
    case CsvColumnType.integer:
      return current is num && current.toInt() == incoming;
    case CsvColumnType.stringList:
      final stored = current is List
          ? current.map((item) => '$item').toList()
          : const <String>[];
      final wanted = incoming as List<String>;
      if (stored.length != wanted.length) return false;
      for (var i = 0; i < stored.length; i++) {
        if (stored[i] != wanted[i]) return false;
      }
      return true;
    case CsvColumnType.timestamp:
      return true;
  }
}

/// `{'title.Urdu': x}` → `{'title': {'Urdu': x}}`. Firestore's merge writes
/// merge nested maps, so other languages in `title` are preserved.
Map<String, dynamic> nestDottedFields(Map<String, Object?> flat) {
  final result = <String, dynamic>{};
  flat.forEach((path, value) {
    final parts = path.split('.');
    var node = result;
    for (final part in parts.take(parts.length - 1)) {
      node = (node[part] ??= <String, dynamic>{}) as Map<String, dynamic>;
    }
    node[parts.last] = value;
  });
  return result;
}
