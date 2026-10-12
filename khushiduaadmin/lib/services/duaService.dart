import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/contentController.dart';
import '../controllers/duaController.dart';
import '../models/auditEntry.dart';
import '../models/audioSlot.dart';
import '../models/duaModel.dart';
import 'auditService.dart';
import 'storageService.dart';

/// Reads and writes duas. Every write is recorded in the change history and
/// tells phones that content changed.
///
/// Throws on failure; screens decide what to say and where to go.
class DuaService {
  final DuaController _duaController = Get.find<DuaController>();

  void listen() {
    duaRef.snapshots().listen((event) {
      for (final change in event.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _duaController.removeDuaFromList(change.doc.id, shouldUpdate: false);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          _duaController.addDuaToList(
            DuaModel.fromMap({...data, 'id': change.doc.id}),
            shouldUpdate: false,
          );
        }
      }
      _duaController.markLoaded();
    }, onError: (Object e) => debugPrint('Duas unavailable: $e'));
  }

  /// Saves [dua], first uploading any [files] picked for its recordings.
  /// A new dua (empty id) gets an id and goes to the end of its sections.
  Future<DuaModel> save(
    DuaModel dua, {
    Map<AudioSlot, html.File> files = const {},
    void Function(String status)? onStatus,
  }) async {
    final isNew = dua.id.isEmpty;
    if (isNew) {
      dua.id = duaRef.doc().id;
      dua.createdAt = DateTime.now();
    }
    final before =
        isNew ? null : (await duaRef.doc(dua.id).get()).data();

    for (final MapEntry(key: slot, value: file) in files.entries) {
      onStatus?.call('Uploading ${slot.label}…');
      dua.setAudio(
        slot,
        await StorageService.upload(file, '${dua.id}/${slot.storageName}'),
      );
    }

    onStatus?.call('Saving…');
    dua.updatedAt = DateTime.now();
    final after = dua.toMap();
    // Merge, so fields this panel does not know about survive an edit.
    await duaRef.doc(dua.id).set(after, SetOptions(merge: !isNew));

    await AuditService.record(
      action: isNew ? AuditAction.create : AuditAction.update,
      collection: 'Dua',
      docId: dua.id,
      label: dua.title,
      before: before,
      after: after,
    );
    Get.find<ContentController>().contentChanged();
    return dua;
  }

  /// Shows or hides [dua] in the app.
  Future<void> setEnabled(DuaModel dua, bool enabled) async {
    final updated = dua.copy()..isEnabled = enabled;
    await save(updated);
  }

  /// Deletes [dua]. Its recordings stay in Storage so the delete can be
  /// undone from History.
  Future<void> delete(DuaModel dua) async {
    final before = (await duaRef.doc(dua.id).get()).data();
    await duaRef.doc(dua.id).delete();
    await AuditService.record(
      action: AuditAction.delete,
      collection: 'Dua',
      docId: dua.id,
      label: dua.title,
      before: before,
    );
    Get.find<ContentController>().contentChanged();
  }

  /// Takes [dua] out of one section, leaving it in its others.
  Future<void> removeFromSection(DuaModel dua, String sectionId) async {
    final updated = dua.copy()
      ..subCategoryIds = [
        for (final id in dua.subCategoryIds)
          if (id != sectionId) id,
      ];
    await save(updated);
  }

  /// Saves the order of the duas in one section, as listed.
  ///
  /// The app sorts each section by `order`, so only the duas shown together
  /// need consistent numbers; the old Duas tab renumbered all 400+ at once.
  Future<void> reorder(List<DuaModel> ordered, {required String sectionName}) =>
      _reorder(duaRef, 'Dua', ordered.map((d) => (d.id, d.order)).toList(),
          label: 'duas in $sectionName', apply: (i) => ordered[i].order = i);

  /// Uploads one recording for each pair and saves it on its dua.
  Future<void> attachAudio(
    List<({DuaModel dua, AudioSlot slot, html.File file})> items, {
    void Function(int done, int total)? onProgress,
  }) async {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final dua = item.dua.copy();
      await save(dua, files: {item.slot: item.file});
      onProgress?.call(i + 1, items.length);
    }
  }
}

/// Renumbers [items] (id, current order) 0, 1, 2… in the order given,
/// writing only those whose position changed, and records one history entry
/// that can put them all back.
Future<void> _reorder(
  CollectionReference<Map<String, dynamic>> ref,
  String collection,
  List<(String, int)> items, {
  required String label,
  required void Function(int index) apply,
}) async {
  final before = <String, dynamic>{};
  final after = <String, dynamic>{};
  final batch = firestore.batch();
  for (var i = 0; i < items.length; i++) {
    final (id, order) = items[i];
    apply(i);
    if (order == i) continue;
    before[id] = order;
    after[id] = i;
    batch.update(ref.doc(id), {'order': i, 'updatedAt': DateTime.now()});
  }
  if (after.isEmpty) return;
  await batch.commit();
  await AuditService.record(
    action: AuditAction.reorder,
    collection: collection,
    docId: '',
    label: label,
    before: before,
    after: after,
  );
  Get.find<ContentController>().contentChanged();
}

/// Shared with the category service.
Future<void> reorderDocs(
  CollectionReference<Map<String, dynamic>> ref,
  String collection,
  List<(String, int)> items, {
  required String label,
  required void Function(int index) apply,
}) =>
    _reorder(ref, collection, items, label: label, apply: apply);
