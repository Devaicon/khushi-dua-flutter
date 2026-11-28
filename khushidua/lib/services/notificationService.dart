import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/notificationController.dart';

import '../models/notificationModel.dart';

/// The in-app inbox: a live listener on the broadcast announcements.
///
/// There are no accounts, so there is nobody to address a notification to:
/// the inbox holds what was sent to everyone (`sentTo == null`). Documents
/// addressed to an old account are never read.
class NotificationService {
  NotificationService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _global;

  static NotificationController get _controller =>
      Get.find<NotificationController>();

  static void bindGlobal() {
    if (_global != null) return;
    _global = notificationRef
        .where('sentTo', isNull: true)
        .snapshots()
        .listen(_apply, onError: _logError);
  }

  static void _apply(QuerySnapshot<Map<String, dynamic>> event) {
    for (final change in event.docChanges) {
      final data = change.doc.data();
      if (data == null) continue;
      if (change.type == DocumentChangeType.removed) {
        _controller.removeWhere((n) => n.id == change.doc.id);
        continue;
      }
      _controller.addNotificationToList(
        NotificationModel.fromMap(data, docId: change.doc.id),
        notify: false,
      );
    }
    _controller.update();
  }

  static void _logError(Object error) {
    debugPrint('🔔 NotificationService: listener failed: $error');
  }
}
