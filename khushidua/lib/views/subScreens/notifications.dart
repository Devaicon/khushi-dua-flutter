import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/controllers/notificationController.dart';

import '../../controllers/userController.dart';
import '../../models/notificationModel.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications".tr)),
      body: GetBuilder<UserController>(
        builder: (userController) {
          return GetBuilder<NotificationController>(
            builder: (notificationController) {
              return ListView.builder(
                itemCount: notificationController.allNotifications.length,
                itemBuilder: (context, index) {
                  return NotificationTile(
                    notificationModel:
                        notificationController.allNotifications[index],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatefulWidget {
  final NotificationModel notificationModel;
  const NotificationTile({super.key, required this.notificationModel});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.notificationModel.title,
          style: TextStyle(color: rblack, fontWeight: FontWeight.bold),
        ).marginSymmetric(horizontal: 10),
        Text(
          widget.notificationModel.message,
          style: TextStyle(color: rblack.withOpacity(0.7)),
        ).marginSymmetric(horizontal: 10),
        Divider(height: 2, color: rblack.withOpacity(0.3)).marginOnly(top: 8),
      ],
    ).marginSymmetric(vertical: 12);
  }
}
