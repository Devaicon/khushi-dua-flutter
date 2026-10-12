import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/authController.dart';
import '../controllers/contentController.dart';
import '../helpers/auditDiff.dart';
import '../models/auditEntry.dart';

/// Writes the change history and undoes changes from it.
///
/// History is best-effort: a change that saved is never reported as failed
/// because its history entry could not be written (for instance before the
/// Firestore rules allowing `AuditLog` are deployed).
abstract final class AuditService {
  static Future<void> record({
    required AuditAction action,
    required String collection,
    required String docId,
    required String label,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    bool undoable = true,
  }) async {
    try {
      final admin = Get.find<AuthController>().adminModel;
      final fields = action == AuditAction.reorder
          ? const <String>['order']
          : changedFields(before, after);
      // An edit that changed nothing worth showing is not worth recording.
      if (action == AuditAction.update && fields.isEmpty) return;
      await auditLogRef.add({
        'action': action.name,
        'collection': collection,
        'docId': docId,
        'label': label,
        'fields': fields,
        'before': before,
        'after': after,
        'undoable': undoable,
        'undone': false,
        'byUid': admin.id,
        'byEmail': admin.email,
        'byName': '${admin.firstName} ${admin.lastName}'.trim(),
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('History entry not written ($label): $e');
    }
  }

  /// Puts back what [entry] changed: deletes a created document, restores
  /// an edited or deleted one, or puts a reordered list back in order.
  static Future<void> undo(AuditEntry entry) async {
    final ref = firestore.collection(entry.collection);
    switch (entry.action) {
      case AuditAction.create:
        await ref.doc(entry.docId).delete();
      case AuditAction.update:
      case AuditAction.delete:
        final before = entry.before;
        if (before == null) {
          throw StateError('This change has no earlier version to restore.');
        }
        await ref.doc(entry.docId).set(before);
      case AuditAction.reorder:
        final batch = firestore.batch();
        entry.before?.forEach((id, order) {
          batch.update(ref.doc(id), {'order': order});
        });
        await batch.commit();
      case AuditAction.restore:
      case AuditAction.other:
        throw StateError('This change cannot be undone.');
    }
    await auditLogRef.doc(entry.id).update({'undone': true});
    await record(
      action: AuditAction.restore,
      collection: entry.collection,
      docId: entry.docId,
      label: '${entry.action.verb.toLowerCase()} ${entry.label}',
      undoable: false,
    );
    Get.find<ContentController>().contentChanged();
  }
}
