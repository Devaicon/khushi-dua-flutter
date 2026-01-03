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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                itemCount: notificationController.allNotifications.length,
                itemBuilder: (context, index) {
                  return NotificationTile(
                    notificationModel:
                        notificationController.allNotifications[index],
                    index: index,
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
  final int index;
  const NotificationTile({
    super.key,
    required this.notificationModel,
    required this.index,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: rbluedark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rbluedark.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: rbluedark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notificationModel.title,
                              style: const TextStyle(
                                color: rbluedark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.notificationModel.message,
                              style: TextStyle(
                                color: rblack.withOpacity(0.6),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
