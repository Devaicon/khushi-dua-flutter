/// What each exportable dataset looks like as a spreadsheet, and how cells
/// convert to and from database values.
library;

enum CsvColumnType { text, boolean, integer, stringList, timestamp }

class CsvColumn {
  const CsvColumn(
    this.field, {
    this.type = CsvColumnType.text,
    this.aliases = const [],
    this.importable = true,
    this.required = false,
    this.isLanguage = false,
    this.blankAsNull = false,
    this.defaultValue,
  });

  /// Database field. A dot means a nested map key, e.g. `title.Urdu`.
  final String field;
  final CsvColumnType type;

  /// Other headers accepted on import — used for correct spellings of the
  /// misspelled language fields and for display names.
  final List<String> aliases;

  /// False for read-only columns such as timestamps.
  final bool importable;

  /// Must have a value when a record is created, and can't be blanked.
  final bool required;

  /// Checked for text destroyed by a non-UTF-8 save.
  final bool isLanguage;

  /// A blank cell is stored as null rather than an empty string.
  final bool blankAsNull;

  /// Written when a record is created without this column.
  final Object? defaultValue;

  bool matchesHeader(String header) {
    final wanted = header.trim().toLowerCase();
    if (wanted == field.toLowerCase()) return true;
    return aliases.any((alias) => alias.toLowerCase() == wanted);
  }
}

enum CsvDataset {
  duas,
  categories,
  subCategories,
  homeBanner,
  notifications,
  users,
  admins,
}

class CsvSchema {
  const CsvSchema({
    required this.dataset,
    required this.label,
    required this.description,
    required this.collection,
    required this.fileStem,
    required this.columns,
    this.importable = true,
    this.singleDocId,
  });

  final CsvDataset dataset;
  final String label;
  final String description;
  final String collection;
  final String fileStem;
  final List<CsvColumn> columns;
  final bool importable;

  /// Set for datasets stored as one document rather than a collection.
  final String? singleDocId;

  List<String> get headers => ['id', for (final c in columns) c.field];
}

/// Database field and display name for every language the app offers.
const List<(String, String)> kLanguageFields = [
  ('english', 'English'),
  ('arabic', 'Arabic'),
  ('bengali', 'Bengali'),
  ('french', 'French'),
  ('german', 'German'),
  ('gujrati', 'Gujarati'),
  ('hindi', 'Hindi'),
  ('indonesian', 'Indonesian'),
  ('japanese', 'Japanese'),
  ('malay', 'Malay'),
  ('mandrain', 'Mandarin'),
  ('marathi', 'Marathi'),
  ('portugese', 'Portuguese'),
  ('punjabi', 'Punjabi'),
  ('russian', 'Russian'),
  ('sindhi', 'Sindhi'),
  ('spanish', 'Spanish'),
  ('tamil', 'Tamil'),
  ('telgu', 'Telugu'),
  ('turkish', 'Turkish'),
  ('urdu', 'Urdu'),
];

final List<CsvColumn> _languageColumns = [
  for (final (field, display) in kLanguageFields)
    CsvColumn(field,
        aliases: [display], isLanguage: true, required: field == 'english'),
];

const List<CsvColumn> _visibilityColumns = [
  CsvColumn('order', type: CsvColumnType.integer, defaultValue: 0),
  CsvColumn('isEnabled', type: CsvColumnType.boolean, defaultValue: true),
  CsvColumn('littleKids', type: CsvColumnType.boolean, defaultValue: true),
  CsvColumn('olderKids', type: CsvColumnType.boolean, defaultValue: true),
  CsvColumn('grownUps', type: CsvColumnType.boolean, defaultValue: true),
];

const List<CsvColumn> _timestampColumns = [
  CsvColumn('createdAt', type: CsvColumnType.timestamp, importable: false),
  CsvColumn('updatedAt', type: CsvColumnType.timestamp, importable: false),
];

final Map<CsvDataset, CsvSchema> kCsvSchemas = {
  CsvDataset.duas: CsvSchema(
    dataset: CsvDataset.duas,
    label: 'Duas',
    description:
        'Every dua with all 21 languages, transliteration, benefits, audience and audio links.',
    collection: 'Dua',
    fileStem: 'duas',
    columns: [
      ..._languageColumns,
      const CsvColumn('transliteration'),
      const CsvColumn('description'),
      const CsvColumn('benefits'),
      const CsvColumn('subCategoryIds',
          type: CsvColumnType.stringList, aliases: ['subCategories']),
      ..._visibilityColumns,
      const CsvColumn('littleKidsAudio'),
      const CsvColumn('olderKidsAudio'),
      const CsvColumn('grownUpsAudio'),
      const CsvColumn('englishTranslation',
          aliases: ['englishTranslationAudio']),
      const CsvColumn('urduTranslation', aliases: ['urduTranslationAudio']),
      ..._timestampColumns,
    ],
  ),
  CsvDataset.categories: CsvSchema(
    dataset: CsvDataset.categories,
    label: 'Categories',
    description: 'Category names in all 21 languages, logo, order and audience.',
    collection: 'Category',
    fileStem: 'categories',
    columns: [
      ..._languageColumns,
      const CsvColumn('logo'),
      ..._visibilityColumns,
      ..._timestampColumns,
    ],
  ),
  CsvDataset.subCategories: CsvSchema(
    dataset: CsvDataset.subCategories,
    label: 'Subcategories',
    description:
        'Subcategory names in all 21 languages, parent category, image, order and audience.',
    collection: 'SubCategory',
    fileStem: 'subcategories',
    columns: [
      ..._languageColumns,
      const CsvColumn('categoryId', required: true),
      const CsvColumn('image'),
      ..._visibilityColumns,
      ..._timestampColumns,
    ],
  ),
  CsvDataset.homeBanner: CsvSchema(
    dataset: CsvDataset.homeBanner,
    label: 'Home banner',
    description:
        'The home screen banner in every language, its image and tap action.',
    collection: 'SystemConfiguration',
    singleDocId: 'HomeBanner',
    fileStem: 'home-banner',
    columns: [
      const CsvColumn('isEnabled',
          type: CsvColumnType.boolean, defaultValue: false),
      const CsvColumn('imageUrl'),
      const CsvColumn('linkCategoryId'),
      for (final (_, display) in kLanguageFields)
        CsvColumn('title.$display',
            isLanguage: true, required: display == 'English'),
      for (final (_, display) in kLanguageFields)
        CsvColumn('subtitle.$display', isLanguage: true),
      const CsvColumn('updatedAt',
          type: CsvColumnType.timestamp, importable: false),
    ],
  ),
  CsvDataset.notifications: const CsvSchema(
    dataset: CsvDataset.notifications,
    label: 'Notifications',
    description:
        "In-app notification history. Imported notifications show in the app's list but are not sent to phones.",
    collection: 'Notifications',
    fileStem: 'notifications',
    columns: [
      CsvColumn('title', required: true),
      CsvColumn('message', required: true),
      CsvColumn('sentTo', blankAsNull: true),
      CsvColumn('createdAt', type: CsvColumnType.timestamp, importable: false),
    ],
  ),
  CsvDataset.users: const CsvSchema(
    dataset: CsvDataset.users,
    label: 'Users',
    description:
        "App users with points and membership. Export only — personal data can't be imported.",
    collection: 'Users',
    fileStem: 'users',
    importable: false,
    columns: [
      CsvColumn('name'),
      CsvColumn('email'),
      CsvColumn('points', type: CsvColumnType.integer),
      CsvColumn('isMember', type: CsvColumnType.boolean),
      CsvColumn('isBlocked', type: CsvColumnType.boolean),
      CsvColumn('readDuas', type: CsvColumnType.stringList),
      ..._timestampColumns,
    ],
  ),
  CsvDataset.admins: const CsvSchema(
    dataset: CsvDataset.admins,
    label: 'Admins',
    description: 'Admin panel operators and their roles. Export only.',
    collection: 'Management',
    fileStem: 'admins',
    importable: false,
    columns: [
      CsvColumn('email'),
      CsvColumn('firstName'),
      CsvColumn('lastName'),
      CsvColumn('role'),
      ..._timestampColumns,
    ],
  ),
};

Object? valueAtPath(Map<String, dynamic> doc, String path) {
  Object? current = doc;
  for (final part in path.split('.')) {
    if (current is! Map) return null;
    current = current[part];
  }
  return current;
}

String formatCell(CsvColumn column, Object? value) {
  switch (column.type) {
    case CsvColumnType.text:
      return value?.toString() ?? '';
    case CsvColumnType.boolean:
      return value is bool ? (value ? 'TRUE' : 'FALSE') : '';
    case CsvColumnType.integer:
      return value is num ? value.toInt().toString() : '';
    case CsvColumnType.stringList:
      return value is List ? value.map((item) => '$item').join('|') : '';
    case CsvColumnType.timestamp:
      return value is DateTime ? value.toUtc().toIso8601String() : '';
  }
}

/// [doc] must already be passed through `normalizeFirestoreValue`.
List<String> exportRow(CsvSchema schema, String id, Map<String, dynamic> doc) =>
    [id, for (final c in schema.columns) formatCell(c, valueAtPath(doc, c.field))];

class CellResult {
  const CellResult.value(this.value)
      : error = null,
        skip = false;
  const CellResult.skip()
      : value = null,
        error = null,
        skip = true;
  const CellResult.error(String this.error)
      : value = null,
        skip = false;

  final Object? value;
  final String? error;

  /// The cell carries no instruction: leave the stored value as it is.
  final bool skip;
}

/// Only question marks and spaces, with at least two question marks — what
/// Arabic, Urdu and similar scripts turn into after a non-UTF-8 save.
final RegExp _corruptedText = RegExp(r'^[?\s]*\?[?\s]*\?[?\s]*$');

CellResult parseCell(CsvColumn column, String raw) {
  if (!column.importable) return const CellResult.skip();
  final text = raw.trim();

  switch (column.type) {
    case CsvColumnType.text:
      if (column.isLanguage && _corruptedText.hasMatch(text)) {
        return CellResult.error(
            '"${column.field}" is only question marks. The file was probably '
            'saved as plain CSV, which destroys non-Latin text. Re-save it as '
            '"CSV UTF-8" and import again.');
      }
      if (column.blankAsNull && text.isEmpty) {
        return const CellResult.value(null);
      }
      return CellResult.value(text);

    case CsvColumnType.boolean:
      if (text.isEmpty) return const CellResult.skip();
      final lower = text.toLowerCase();
      if (const {'true', 'yes', 'y', '1'}.contains(lower)) {
        return const CellResult.value(true);
      }
      if (const {'false', 'no', 'n', '0'}.contains(lower)) {
        return const CellResult.value(false);
      }
      return CellResult.error(
          '"${column.field}" must be TRUE or FALSE, not "$text".');

    case CsvColumnType.integer:
      if (text.isEmpty) return const CellResult.skip();
      final whole = int.tryParse(text);
      if (whole != null) return CellResult.value(whole);
      final decimal = double.tryParse(text);
      if (decimal != null && decimal == decimal.truncateToDouble()) {
        return CellResult.value(decimal.toInt());
      }
      return CellResult.error(
          '"${column.field}" must be a whole number, not "$text".');

    case CsvColumnType.stringList:
      return CellResult.value([
        for (final part in text.split('|'))
          if (part.trim().isNotEmpty) part.trim(),
      ]);

    case CsvColumnType.timestamp:
      return const CellResult.skip();
  }
}

class HeaderMapping {
  const HeaderMapping({
    required this.idIndex,
    required this.columnIndexes,
    required this.errors,
  });

  final int idIndex;
  final Map<CsvColumn, int> columnIndexes;

  /// Problems with the header row. Any error blocks the whole import.
  final List<String> errors;
}

HeaderMapping mapHeaders(CsvSchema schema, List<String> headers) {
  final errors = <String>[];
  final indexes = <CsvColumn, int>{};
  var idIndex = -1;

  for (var i = 0; i < headers.length; i++) {
    final header = headers[i].trim();
    if (header.isEmpty) continue;

    if (header.toLowerCase() == 'id') {
      if (idIndex != -1) errors.add('The "id" column appears more than once.');
      idIndex = i;
      continue;
    }

    final matches = schema.columns.where((c) => c.matchesHeader(header));
    if (matches.isEmpty) {
      errors.add('Unknown column "$header". Export ${schema.label} to see '
          'the columns it accepts.');
      continue;
    }
    final column = matches.first;
    if (indexes.containsKey(column)) {
      errors.add('Two columns both mean "${column.field}". Keep one.');
      continue;
    }
    indexes[column] = i;
  }

  if (idIndex == -1) {
    errors.add('The file needs an "id" column. Leave an id blank to create a '
        'new record.');
  }

  return HeaderMapping(
      idIndex: idIndex, columnIndexes: indexes, errors: errors);
}
