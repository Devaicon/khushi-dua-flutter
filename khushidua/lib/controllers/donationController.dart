import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/donationSettings.dart';
import 'reminderController.dart';

/// Follows `SystemConfiguration/Donations`, so the admin panel can show or
/// hide each donation card, strip and reminder without an app release.
///
/// Firestore's offline cache serves the last known switches at launch; until
/// anything is known every placement is shown, as before the switches.
class DonationController extends GetxController {
  DonationSettings _settings = const DonationSettings();
  DonationSettings get settings => _settings;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = sysConfigRef
        .doc(DonationSettings.docId)
        .snapshots()
        .listen(
          (snap) => _apply(DonationSettings.fromMap(snap.data())),
          onError: (Object e) =>
              debugPrint('💝 Donation settings unavailable: $e'),
        );
  }

  void _apply(DonationSettings next) {
    final reminderChanged = next.reminder != _settings.reminder;
    _settings = next;
    update();
    if (reminderChanged) {
      Get.find<ReminderController>().setSupportAllowed(next.reminder);
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
