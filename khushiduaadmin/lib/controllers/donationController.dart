import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/donationSettings.dart';
import '../widgets/customSnackbar.dart';

/// Reads and writes `SystemConfiguration/Donations`. The app listens to the
/// same document, so a save reaches every running app at once — no release.
class DonationController extends GetxController {
  DonationSettings _settings = const DonationSettings();
  DonationSettings get settings => _settings;

  bool _loading = false;
  bool get loading => _loading;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    _loading = true;
    update();
    try {
      final snap = await sysConfigRef.doc(DonationSettings.docId).get();
      _settings = DonationSettings.fromMap(snap.data());
      _loaded = true;
    } catch (e) {
      debugPrint('Error loading donation settings: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to load the donation settings",
        isSuccess: false,
      );
    }
    _loading = false;
    update();
  }

  Future<bool> save(DonationSettings settings) async {
    _loading = true;
    update();
    try {
      await sysConfigRef.doc(DonationSettings.docId).set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _settings = settings;
      CustomSnackbar.show("Success", "Donation settings published");
      return true;
    } catch (e) {
      debugPrint('Error saving donation settings: $e');
      CustomSnackbar.show(
        "Error",
        "Failed to save the donation settings",
        isSuccess: false,
      );
      return false;
    } finally {
      _loading = false;
      update();
    }
  }
}
