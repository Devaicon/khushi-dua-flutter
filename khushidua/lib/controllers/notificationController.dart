import 'package:get/get.dart';
import 'package:khushidua/services/notificationService.dart';

import '../models/notificationModel.dart';

class NotificationController extends GetxController {
  final List<NotificationModel> _allNotifications = [];

  /// Newest first.
  List<NotificationModel> get allNotifications => _allNotifications;

  void addNotificationToList(
    NotificationModel notificationModel, {
    bool notify = true,
  }) {
    final existingIndex = _allNotifications.indexWhere(
      (n) => n.id == notificationModel.id,
    );

    if (existingIndex == -1) {
      _allNotifications.add(notificationModel);
    } else {
      _allNotifications[existingIndex] = notificationModel;
    }
    _allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (notify) update();
  }

  void removeWhere(bool Function(NotificationModel) test) {
    final before = _allNotifications.length;
    _allNotifications.removeWhere(test);
    if (_allNotifications.length != before) update();
  }

  /// Safe to call repeatedly: each listener is opened at most once.
  void getAllNotifications({String? userId}) {
    NotificationService.bindGlobal();
    if (userId != null) NotificationService.bindUser(userId);
  }

  /// Follows the signed-in user; pass null on sign-out.
  void bindUser(String? userId) => NotificationService.bindUser(userId);

  void clearNotifications() {
    _allNotifications.clear();
    update();
  }
}
