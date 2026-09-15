import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firebaseRef.dart';
import '../csv/csvCodec.dart';
import '../csv/csvSchema.dart';
import '../csv/firestoreValues.dart';
import '../csv/importPlanner.dart';
import '../helpers/webFiles.dart';

/// Firestore allows 500 writes per batch; stay well under it.
const int kImportBatchSize = 400;

class ImportApplyException implements Exception {
  ImportApplyException({
    required this.written,
    required this.total,
    required this.failedAtRow,
    required this.cause,
  });

  final int written;
  final int total;
  final int failedAtRow;
  final Object cause;

  String describe() =>
      'Saved $written of $total changes, then failed at spreadsheet row '
      '$failedAtRow: $cause\n\nThe backup file downloaded just before the '
      'import has the data as it was.';
}

class CsvTransferService {
  static String _stamp() =>
      DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '-');

  Future<Map<String, Map<String, dynamic>>> _fetch(CsvSchema schema) async {
    final collection = firestore.collection(schema.collection);

    Map<String, dynamic> clean(Map<String, dynamic> data) =>
        normalizeFirestoreValue(data) as Map<String, dynamic>;

    final singleId = schema.singleDocId;
    if (singleId != null) {
      final snapshot = await collection.doc(singleId).get();
      final data = snapshot.data();
      return {if (data != null) singleId: clean(data)};
    }

    final snapshot = await collection.get();
    return {for (final doc in snapshot.docs) doc.id: clean(doc.data())};
  }

  /// Downloads the dataset as CSV. Returns the number of rows exported.
  Future<int> export(CsvSchema schema, {String prefix = ''}) async {
    final docs = await _fetch(schema);
    final ids = docs.keys.toList()
      ..sort((a, b) {
        final orderA = docs[a]!['order'];
        final orderB = docs[b]!['order'];
        if (orderA is num && orderB is num && orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        return a.compareTo(b);
      });

    final rows = [for (final id in ids) exportRow(schema, id, docs[id]!)];
    downloadTextFile(
      '$prefix${schema.fileStem}-${_stamp()}.csv',
      encodeCsv(schema.headers, rows),
    );
    return rows.length;
  }

  /// Reads [bytes] and compares them with the database. Writes nothing.
  /// Throws [CsvFormatException] when the file itself can't be read.
  Future<ImportPlan> plan(CsvSchema schema, Uint8List bytes) async {
    final table = decodeCsvBytes(bytes);
    final existing = await _fetch(schema);

    var categoryIds = <String>{};
    var subCategoryIds = <String>{};
    if (schema.dataset == CsvDataset.subCategories ||
        schema.dataset == CsvDataset.homeBanner) {
      categoryIds = (await categoryRef.get()).docs.map((d) => d.id).toSet();
    }
    if (schema.dataset == CsvDataset.duas) {
      subCategoryIds =
          (await subCategoryRef.get()).docs.map((d) => d.id).toSet();
    }

    return planImport(
      schema: schema,
      table: table,
      existing: existing,
      knownCategoryIds: categoryIds,
      knownSubCategoryIds: subCategoryIds,
    );
  }

  /// Downloads a backup of the dataset as it is now, then writes every create
  /// and update in the plan. Returns the number of rows written.
  Future<int> apply(ImportPlan plan) async {
    if (!plan.canApply) {
      throw StateError('This import has errors and cannot be applied.');
    }

    await export(plan.schema, prefix: 'backup-');

    final schema = plan.schema;
    final collection = firestore.collection(schema.collection);
    final pending = plan.rows
        .where((r) =>
            r.status == RowStatus.create || r.status == RowStatus.update)
        .toList();

    var written = 0;
    for (var start = 0; start < pending.length; start += kImportBatchSize) {
      final chunk = pending.sublist(
          start, min(start + kImportBatchSize, pending.length));
      final batch = firestore.batch();

      for (final row in chunk) {
        final docId = schema.singleDocId ??
            (row.id.isNotEmpty ? row.id : collection.doc().id);
        final data = nestDottedFields(row.changes)
          ..['updatedAt'] = FieldValue.serverTimestamp();

        if (row.status == RowStatus.create && schema.singleDocId == null) {
          // The app's models read the id from the document body.
          data['id'] = docId;
          data['createdAt'] = FieldValue.serverTimestamp();
        }

        batch.set(collection.doc(docId), data, SetOptions(merge: true));
      }

      try {
        await batch.commit();
      } catch (e) {
        throw ImportApplyException(
          written: written,
          total: pending.length,
          failedAtRow: chunk.first.rowNumber,
          cause: e,
        );
      }
      written += chunk.length;
    }

    return written;
  }
}
