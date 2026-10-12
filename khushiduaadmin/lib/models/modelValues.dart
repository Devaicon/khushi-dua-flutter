/// Lenient readers for Firestore values, shared by the content models.
///
/// Documents have been written by several versions of the panel, CSV imports
/// and the console, so a field can be missing, null, or of a different type
/// from the one expected. These never throw.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

String readString(dynamic value) => value is String ? value : '';

bool readBool(dynamic value, {bool fallback = true}) =>
    value is bool ? value : fallback;

int readInt(dynamic value) => value is num ? value.toInt() : 0;

DateTime readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

List<String> readStringList(dynamic value) =>
    value is List ? [for (final v in value) if (v is String) v] : <String>[];
