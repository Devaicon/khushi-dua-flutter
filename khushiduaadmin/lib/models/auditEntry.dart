import 'modelValues.dart';

enum AuditAction {
  create('Created'),
  update('Edited'),
  delete('Deleted'),
  reorder('Reordered'),
  restore('Undid'),
  other('Changed');

  const AuditAction(this.verb);
  final String verb;

  static AuditAction parse(Object? value) => AuditAction.values.firstWhere(
        (a) => a.name == value,
        orElse: () => AuditAction.other,
      );
}

/// One change made from the panel, kept in the `AuditLog` collection.
///
/// [before] and [after] are the document as it was and became, so a change
/// can be undone. For a reorder they map document ids to positions.
class AuditEntry {
  AuditEntry({
    required this.id,
    required this.action,
    required this.collection,
    required this.docId,
    required this.label,
    required this.fields,
    required this.byEmail,
    required this.byName,
    required this.at,
    required this.undoable,
    this.before,
    this.after,
    this.undone = false,
  });

  factory AuditEntry.fromMap(String id, Map<String, dynamic> map) => AuditEntry(
        id: id,
        action: AuditAction.parse(map['action']),
        collection: readString(map['collection']),
        docId: readString(map['docId']),
        label: readString(map['label']),
        fields: readStringList(map['fields']),
        byEmail: readString(map['byEmail']),
        byName: readString(map['byName']),
        at: readDate(map['at']),
        undoable: readBool(map['undoable'], fallback: false),
        undone: readBool(map['undone'], fallback: false),
        before: map['before'] is Map
            ? Map<String, dynamic>.from(map['before'] as Map)
            : null,
        after: map['after'] is Map
            ? Map<String, dynamic>.from(map['after'] as Map)
            : null,
      );

  final String id;
  final AuditAction action;

  /// The Firestore collection changed: Dua, Category, SubCategory, …
  final String collection;
  final String docId;

  /// What was changed, as a reader would name it ("Dua: Bismillah").
  final String label;

  /// The fields an edit changed.
  final List<String> fields;
  final String byEmail;
  final String byName;
  final DateTime at;
  final bool undoable;

  /// Set once someone has undone this change.
  final bool undone;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  String get by => byName.trim().isNotEmpty ? byName : byEmail;

  /// "Dua", "Category", "Section", …
  String get kind => switch (collection) {
        'Dua' => 'Dua',
        'Category' => 'Category',
        'SubCategory' => 'Section',
        'Users' => 'User',
        'Notifications' => 'Notification',
        'SystemConfiguration' => 'App setting',
        _ => collection,
      };
}
