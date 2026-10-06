import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/constants/theme.dart';
import 'package:khushidua/controllers/notificationController.dart';
import '../../animations/fadeInAnimationBTT.dart';
import '../../models/notificationModel.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

/// The announcements inbox, opened from the bell on the home screen.
class _NotificationScreenState extends State<NotificationScreen> {
  final _controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _controller.markAllSeen();
  }

  @override
  void dispose() {
    // Anything that arrived while the inbox was open has been seen too.
    _controller.markAllSeen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      appBar: AppBar(
        title: Text(
          "Notifications".tr,
          style: TextStyle(fontWeight: FontWeight.bold, color: rbluedark),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: rbluedark),
        actions: [
          TextButton(
            onPressed: _confirmClearAll,
            child: Text(
              "Clear All".tr,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GetBuilder<NotificationController>(
        builder: (notificationController) {
          // Everything is shown. Notifications mentioning "test" used to be
          // hidden here, so an admin's test send never reached the inbox.
          final activeNotifications = notificationController.allNotifications;

          if (activeNotifications.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: activeNotifications.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final notification = activeNotifications[index];
              // Swipe either way to delete.
              return Dismissible(
                key: ValueKey(notification.id),
                onDismissed: (_) =>
                    notificationController.deleteNotification(notification.id),
                background: _deleteBackground(Alignment.centerLeft),
                secondaryBackground: _deleteBackground(Alignment.centerRight),
                child: NotificationTile(
                  notificationModel: notification,
                  index: index,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    if (_controller.allNotifications.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete all notifications?".tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: Text("Delete".tr),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.clearNotifications();
  }

  Widget _deleteBackground(Alignment alignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      alignment: alignment,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: rbluedark.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 60,
              color: rbluedark.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "All caught up!".tr,
            style: TextStyle(
              color: rbluedark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You have no new notifications".tr,
            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notificationModel;
  final int index;
  const NotificationTile({
    super.key,
    required this.notificationModel,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimationBTT(
      delay: index * 0.5, // 0.5 staggered delay
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppSurface.card,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: rbluedark.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: rbluedark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notificationModel.title,
                                      style: TextStyle(
                                        color: rbluedark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${notificationModel.createdAt.day}/${notificationModel.createdAt.month}",
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notificationModel.message,
                                style: TextStyle(
                                  color: rtext.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  height: 1.5,
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
      ),
    );
  }
}
