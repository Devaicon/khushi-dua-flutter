import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/modelValues.dart';

/// Tells phones when content has changed.
///
/// The app keeps categories, sections and duas on the device and downloads
/// them again only when `SystemConfiguration/ContentVersion` moves (or once
/// a day). Cloud Functions were meant to move it on every write but were
/// never deployed, so edits could take a day to reach phones. The panel now
/// moves it itself after every content save, a couple of seconds after the
/// last one so a burst of edits counts once.
class ContentController extends GetxController {
  static const String docId = 'ContentVersion';
  static const Duration _settle = Duration(seconds: 2);

  int? _version;
  int? get version => _version;

  DateTime? _publishedAt;
  DateTime? get publishedAt => _publishedAt;

  bool _publishing = false;
  bool get publishing => _publishing;

  /// A save happened and phones have not been told yet.
  bool get pending => _timer?.isActive ?? false;

  Timer? _timer;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = sysConfigRef.doc(docId).snapshots().listen(
      (snap) {
        final data = snap.data();
        _version = data?['version'] is int ? data!['version'] as int : null;
        _publishedAt =
            data?['updatedAt'] == null ? null : readDate(data!['updatedAt']);
        update();
      },
      onError: (Object e) => debugPrint('Content version unavailable: $e'),
    );
  }

  /// Call after any change to categories, sections or duas.
  void contentChanged() {
    _timer?.cancel();
    _timer = Timer(_settle, publish);
    update();
  }

  /// Makes every phone download content again on its next launch.
  Future<bool> publish() async {
    _timer?.cancel();
    _publishing = true;
    update();
    try {
      await sysConfigRef.doc(docId).set({
        'version': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Could not publish content: $e');
      return false;
    } finally {
      _publishing = false;
      update();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _sub?.cancel();
    super.onClose();
  }
}
