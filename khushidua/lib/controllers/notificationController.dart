import 'package:get/get.dart';
import 'package:khushidua/services/notificationService.dart';

import '../models/notificationModel.dart';

class NotificationController extends GetxController {
  final List<NotificationModel> _allNotifications = [];
  List<NotificationModel> get allNotifications => _allNotifications;

  addNotificationToList(NotificationModel notificationModel) {
    int existingIndex = _allNotifications.indexWhere(
      (cat) => cat.id == notificationModel.id,
    );

    if (existingIndex == -1) {
      _allNotifications.add(notificationModel);
    } else {
      _allNotifications[existingIndex] = notificationModel;
    }
    _allNotifications.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    update();
  }

  getAllNotifications() {
    NotificationService().getAllNotifications();
  }

  clearNotifications() {
    _allNotifications.clear();
    update();
  }
}
