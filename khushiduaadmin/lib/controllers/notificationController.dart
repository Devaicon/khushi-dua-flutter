import 'package:get/get.dart';

import '../models/notificationModel.dart';
import '../models/userModel.dart';
import '../services/notificationService.dart';

class NotificationController extends GetxController {
  final List<NotificationModel> _allNotifications = [];
  List<NotificationModel> get allNotifications => _allNotifications;

  void addNotificationToList(NotificationModel notificationModel,
      {bool shouldUpdate = true}) {
    int existingIndex =
        _allNotifications.indexWhere((cat) => cat.id == notificationModel.id);
    if (existingIndex == -1) {
      _allNotifications.add(notificationModel);
    } else {
      _allNotifications[existingIndex] = notificationModel;
    }
    _allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (shouldUpdate) update();
  }

  getAllNotifications() {
    NotificationService().getAllNotifications();
  }

  sendGlobalNotification(String title, String description) async {
    await NotificationService().sendGlobalNotification(title, description);
  }

  sendIndividualNotification(
      UserModel user, String title, String message) async {
    await NotificationService()
        .sendIndividualNotification(user, title, message);
  }
}
