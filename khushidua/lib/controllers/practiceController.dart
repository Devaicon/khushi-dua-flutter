import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/practiceSettings.dart';

/// Follows `SystemConfiguration/MemoizationURL`, so the admin panel can grey
/// out the Practice button, or point it at a new server, without a release.
///
/// One listener for the whole app; each dua card used to fetch the document
/// for itself when it was built.
class PracticeController extends GetxController {
  PracticeSettings _settings = const PracticeSettings();
  PracticeSettings get settings => _settings;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = sysConfigRef
        .doc(PracticeSettings.docId)
        .snapshots()
        .listen(
          (snap) {
            _settings = PracticeSettings.fromMap(snap.data());
            update();
          },
          onError: (Object e) =>
              debugPrint('🎙️ Practice settings unavailable: $e'),
        );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
