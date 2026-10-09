import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/notificationController.dart';
import 'package:khushiduaadmin/models/notificationModel.dart';
import 'package:khushiduaadmin/models/userModel.dart';

import '../widgets/customSnackbar.dart';

/// Sends push notifications by calling admin-gated Cloud Functions.
///
/// The service-account private key that used to live in this file has been
/// removed. Credentials never reach the browser: the functions run server-side
/// under the runtime's own identity and verify the caller is in /Management.
class NotificationService {
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: "us-central1");

  getAllNotifications() async {
    notificationRef.snapshots().listen(
      (event) {
        bool changed = false;
        for (var element in event.docChanges) {
          if (element.type == DocumentChangeType.removed) {
            _notificationController.removeNotificationFromList(element.doc.id,
                shouldUpdate: false);
            changed = true;
          } else if (element.type == DocumentChangeType.added ||
              element.type == DocumentChangeType.modified) {
            _notificationController.addNotificationToList(
              NotificationModel.fromMap(element.doc.data()!),
              shouldUpdate: false,
            );
            changed = true;
          }
        }
        if (changed) _notificationController.update();
      },
      onError: (error) {
        CustomSnackbar.show(
          "Failed".tr,
          "Could not load notifications: $error",
          isSuccess: false,
        );
      },
    );
  }

  /// Turns a FunctionsException into something an operator can act on.
  String _describe(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case "unauthenticated":
          return "Your admin session expired. Sign in again.";
        case "permission-denied":
          return "This account is not an admin.";
        case "not-found":
          return "That user no longer exists.";
        case "invalid-argument":
          return error.message ?? "Title and message are required.";
        default:
          return error.message ?? "Send failed (${error.code}).";
      }
    }
    return "Send failed: $error";
  }

  /// Deletes a notification for everyone: the app's inboxes listen to this
  /// collection and drop it live. Pushes already on a device's lock screen
  /// stay there; only the in-app copy goes.
  Future<bool> deleteNotification(NotificationModel notification) async {
    try {
      await notificationRef.doc(notification.id).delete();
      CustomSnackbar.show(
        "Deleted".tr,
        "\"${notification.title}\" was removed from every inbox.",
        isSuccess: true,
      );
      return true;
    } catch (e) {
      CustomSnackbar.show(
        "Failed".tr,
        "Could not delete the notification: $e",
        isSuccess: false,
      );
      return false;
    }
  }

  Future<void> sendGlobalNotification(String title, String description) async {
    try {
      final result = await _functions.httpsCallable("sendGlobalNotification").call({
        "title": title,
        "message": description,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final success = data["successCount"] ?? 0;
      final failed = data["failureCount"] ?? 0;

      CustomSnackbar.show(
        "Sent".tr,
        failed == 0
            ? "Delivered to $success device(s)."
            : "Delivered to $success device(s), $failed failed.",
        isSuccess: true,
      );
    } catch (e) {
      CustomSnackbar.show("Failed".tr, _describe(e), isSuccess: false);
    }
  }

  Future<void> sendIndividualNotification(
    UserModel user,
    String title,
    String msg,
  ) async {
    try {
      final result =
          await _functions.httpsCallable("sendIndividualNotification").call({
        "userId": user.id,
        "title": title,
        "message": msg,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final delivered = data["delivered"] == true;

      CustomSnackbar.show(
        "Sent".tr,
        delivered
            ? "Notification delivered to ${user.name}."
            : "Saved to ${user.name}'s inbox (no active device).",
        isSuccess: true,
      );
    } catch (e) {
      CustomSnackbar.show("Failed".tr, _describe(e), isSuccess: false);
    }
  }
}
