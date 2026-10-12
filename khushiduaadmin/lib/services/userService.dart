import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/notificationController.dart';
import '../controllers/userController.dart';
import '../models/auditEntry.dart';
import '../models/userModel.dart';
import 'auditService.dart';

class UserService {
  final UserController _userController = Get.find<UserController>();

  void getAllUsers() {
    userRef.snapshots().listen((event) {
      for (final change in event.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _userController.removeUser(change.doc.id);
        } else if (change.doc.data() != null) {
          _userController.addUserToList(
            UserModel.fromMap({...change.doc.data()!, 'id': change.doc.id}),
            shouldUpdate: false,
          );
        }
      }
      _userController.markLoaded();
    }, onError: (Object e) => debugPrint('Users unavailable: $e'));
  }

  Future<void> _set(UserModel user, String field, bool value, String label) async {
    await userRef.doc(user.id).update({field: value});
    // Not undoable: restoring a whole profile would also roll back the
    // reader's own progress since.
    await AuditService.record(
      action: AuditAction.update,
      collection: 'Users',
      docId: user.id,
      label: label,
      before: {field: !value},
      after: {field: value},
      undoable: false,
    );
  }

  /// Grants or ends membership, and tells the reader.
  Future<void> setMember(UserModel user, bool member, {bool notify = true}) async {
    await _set(user, 'isMember', member, user.name.isEmpty ? user.email : user.name);
    if (!notify) return;
    await Get.find<NotificationController>().sendIndividualNotification(
      user,
      member ? 'Account upgraded' : 'Membership ended',
      member
          ? 'You have successfully purchased premium membership.'
          : 'Your account membership has expired.',
    );
  }

  /// Blocks or unblocks the reader, and tells them.
  Future<void> setBlocked(UserModel user, bool blocked, {bool notify = true}) async {
    await _set(user, 'isBlocked', blocked, user.name.isEmpty ? user.email : user.name);
    if (!notify) return;
    await Get.find<NotificationController>().sendIndividualNotification(
      user,
      blocked ? 'Account suspended' : 'Account activated',
      blocked
          ? 'Your account has been blocked due to malicious activity.'
          : 'Your account has been unbanned.',
    );
  }
}
