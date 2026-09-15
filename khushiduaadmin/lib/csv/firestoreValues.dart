import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore-specific types into plain Dart values, so the CSV layer
/// never depends on Firestore. Timestamps become UTC DateTimes.
Object? normalizeFirestoreValue(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): normalizeFirestoreValue(entry.value),
    };
  }
  if (value is List) {
    return [for (final item in value) normalizeFirestoreValue(item)];
  }
  return value;
}
