import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/auditEntry.dart';
import '../models/appVersion.dart';
import '../services/auditService.dart';
import '../widgets/customSnackbar.dart';

/// Reads and writes `SystemConfiguration/AppVersion`. The app reads it at
/// launch and asks readers on an older build to update.
class AppVersionController extends GetxController {
  AppVersion _version = const AppVersion();
  AppVersion get version => _version;

  bool _loading = false;
  bool get loading => _loading;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    _loading = true;
    update();
    try {
      final snap = await sysConfigRef.doc(AppVersion.docId).get();
      _version = AppVersion.fromMap(snap.data());
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading update prompt settings: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to load the update prompt settings",
        isSuccess: false,
      );
    }
    _loading = false;
    update();
  }

  Future<bool> save(AppVersion version) async {
    _loading = true;
    update();
    try {
      final ref = sysConfigRef.doc(AppVersion.docId);
      final before = (await ref.get()).data();
      await ref.set({
        ...version.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AuditService.record(
        action: before == null ? AuditAction.create : AuditAction.update,
        collection: 'SystemConfiguration',
        docId: AppVersion.docId,
        label: 'Update prompt',
        before: before,
        after: (await ref.get()).data(),
      );
      _version = version;
      CustomSnackbar.show("Success", "Update prompt published");
      return true;
    } catch (e) {
      debugPrint('Error saving update prompt settings: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to save the update prompt settings",
        isSuccess: false,
      );
      return false;
    } finally {
      _loading = false;
      update();
    }
  }
}
