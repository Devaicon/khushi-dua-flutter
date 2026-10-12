import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../models/auditEntry.dart';

/// The most recent changes made from the panel, live.
class HistoryController extends GetxController {
  static const int limit = 300;

  List<AuditEntry> _entries = [];
  List<AuditEntry> get entries => _entries;

  bool _loaded = false;
  bool get loaded => _loaded;

  /// False when the history cannot be read — usually because the Firestore
  /// rules that allow `AuditLog` have not been deployed yet.
  bool _available = true;
  bool get available => _available;

  StreamSubscription? _sub;

  void start() {
    _sub ??= auditLogRef
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .listen(
      (snap) {
        _entries = [
          for (final doc in snap.docs) AuditEntry.fromMap(doc.id, doc.data()),
        ];
        _loaded = true;
        _available = true;
        update();
      },
      onError: (Object e) {
        debugPrint('History unavailable: $e');
        _loaded = true;
        _available = !(e is FirebaseException && e.code == 'permission-denied');
        update();
      },
    );
  }

  /// The changes made to one document, newest first.
  List<AuditEntry> forDoc(String docId) =>
      [for (final e in _entries) if (e.docId == docId) e];

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
