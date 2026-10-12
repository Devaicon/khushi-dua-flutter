import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/mlSettingsController.dart';
import '../models/auditEntry.dart';
import '../models/mlSettingsModel.dart';
import '../widgets/customSnackbar.dart';
import 'auditService.dart';

/// Reads and writes `SystemConfiguration/MemoizationURL`: the Practice
/// button's switch and the server it sends recordings to. The app listens to
/// this document, so changes reach running apps within seconds.
class MLSettingsService {
  static const String docId = 'MemoizationURL';

  final MLSettingsController _controller = Get.find<MLSettingsController>();

  Future<void> getMLSettings() async {
    try {
      _controller.setLoading(true);
      final snap = await sysConfigRef.doc(docId).get();
      _controller.setMLSettings(snap.exists && snap.data() != null
          ? MLSettingsModel.fromMap({...snap.data()!, "id": snap.id})
          : null);
    } catch (e) {
      debugPrint("Error getting ML Settings: $e");
      CustomSnackbar.show("Couldn't load", "The Practice settings could not be read.",
          isSuccess: false);
    } finally {
      _controller.setLoading(false);
    }
  }

  Future<void> _write(Map<String, dynamic> changes, String done) async {
    try {
      _controller.setLoading(true);
      final before = (await sysConfigRef.doc(docId).get()).data();
      await sysConfigRef.doc(docId).set(
          {...changes, "updatedAt": DateTime.now()}, SetOptions(merge: true));
      final after = (await sysConfigRef.doc(docId).get()).data();
      await AuditService.record(
        action: before == null ? AuditAction.create : AuditAction.update,
        collection: 'SystemConfiguration',
        docId: docId,
        label: 'Practice settings',
        before: before,
        after: after,
      );
      await getMLSettings();
      CustomSnackbar.show("Saved", done);
    } catch (e) {
      debugPrint("Error saving ML Settings: $e");
      _controller.setLoading(false);
      CustomSnackbar.show("Couldn't save", "$e", isSuccess: false);
    }
  }

  /// Sets the transcription server Practice sends recordings to.
  Future<void> saveUrl(String url) =>
      _write({"URL": url}, "Practice now sends recordings to $url");

  /// Turns the app's Practice button on or off.
  Future<void> setPracticeEnabled(bool enabled) => _write(
        {"practiceEnabled": enabled},
        enabled
            ? "Practice is on in the app"
            : "Practice is greyed out in the app",
      );
}
