import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/notificationController.dart';

import '../models/notificationModel.dart';

/// The in-app inbox: live listeners on the Notifications collection.
///
/// Two listeners, each opened at most once: one for broadcasts, and one for
/// the signed-in user's own notifications. The user listener is rebound when
/// the user changes — it used to be opened only if a user was already loaded
/// when the dashboard started, which it never was, so individual notifications
/// never reached the inbox.
class NotificationService {
  NotificationService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _global;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _personal;
  static String? _boundUserId;

  static NotificationController get _controller =>
      Get.find<NotificationController>();

  static void bindGlobal() {
    if (_global != null) return;
    _global = notificationRef
        .where('sentTo', isNull: true)
        .snapshots()
        .listen(_apply, onError: _logError);
  }

  /// Points the personal listener at [userId], or closes it for a guest.
  static Future<void> bindUser(String? userId) async {
    final id = (userId == null || userId.isEmpty) ? null : userId;
    if (id == _boundUserId && (id == null || _personal != null)) return;

    await _personal?.cancel();
    _personal = null;
    _boundUserId = id;
    // Drop the previous user's notifications so they do not linger after a
    // sign-out or an account switch.
    _controller.removeWhere((n) => n.sentTo != null && n.sentTo != id);

    if (id == null) return;
    _personal = notificationRef
        .where('sentTo', isEqualTo: id)
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
