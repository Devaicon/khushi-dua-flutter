import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/auditEntry.dart';
import '../models/storeLinks.dart';
import '../services/auditService.dart';
import '../widgets/customSnackbar.dart';

/// Reads and writes `SystemConfiguration/StoreLinks`. The app reads the same
/// document each time a reader taps Share App, so a save needs no release.
class StoreLinksController extends GetxController {
  StoreLinks _links = const StoreLinks();
  StoreLinks get links => _links;

  bool _loading = false;
  bool get loading => _loading;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    _loading = true;
    update();
    try {
      final snap = await sysConfigRef.doc(StoreLinks.docId).get();
      _links = StoreLinks.fromMap(snap.data());
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading store links: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to load the store links",
        isSuccess: false,
      );
    }
    _loading = false;
    update();
  }

  Future<bool> save(StoreLinks links) async {
    _loading = true;
    update();
    try {
      final ref = sysConfigRef.doc(StoreLinks.docId);
      final before = (await ref.get()).data();
      await ref.set({
        ...links.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AuditService.record(
        action: before == null ? AuditAction.create : AuditAction.update,
        collection: 'SystemConfiguration',
        docId: StoreLinks.docId,
        label: 'Store links',
        before: before,
        after: (await ref.get()).data(),
      );
      _links = links;
      CustomSnackbar.show("Success", "Store links published");
      return true;
    } catch (e) {
      debugPrint('Error saving store links: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to save the store links",
        isSuccess: false,
      );
      return false;
    } finally {
      _loading = false;
      update();
    }
  }
}
