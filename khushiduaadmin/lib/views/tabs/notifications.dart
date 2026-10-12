import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/notificationController.dart';
import '../../controllers/userController.dart';
import '../../models/notificationModel.dart';
import '../../search/adminSearch.dart';
import '../../widgets/adminSearchField.dart';
import '../../widgets/ui.dart';
import 'users.dart';

/// Notifications sent to readers, and sending a new one to everyone.
class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  String _query = '';
  final Set<String> _deleting = {};

  Future<void> _delete(NotificationModel n) async {
    if (!await confirmAction(
      context,
      title: 'Delete this notification?',
      message: n.sentTo == null
          ? '"${n.title}" will be removed from every reader\'s notifications '
              'in the app. Pushes already on phones stay there.'
          : '"${n.title}" will be removed from this reader\'s notifications.',
      confirmLabel: 'Delete',
      danger: true,
    )) {
      return;
    }
    setState(() => _deleting.add(n.id));
    final ok = await Get.find<NotificationController>().deleteNotification(n);
    if (!ok && mounted) setState(() => _deleting.remove(n.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<UserController>(
        builder: (users) => GetBuilder<NotificationController>(
          builder: (c) {
            final all = c.allNotifications;
            final visible = filterBySearch(all, _query, notificationSearchFields);
            return AdminPage(
              scroll: false,
              title: 'Notifications',
              subtitle: 'What readers see in the app\'s notifications list. '
                  'Sending one also pushes it to their phones.',
              actions: [
                AdminButton(
                  label: 'Notify everyone',
                  icon: Icons.campaign_outlined,
                  onPressed: () => showMessageDialog(context),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSearchField(
                    hint: 'Search by title or message',
                    matchCount: visible.length,
                    totalCount: all.length,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: Space.lg),
                  Expanded(
                    child: AdminTable(
                      columns: const [
                        TableCol('Notification', flex: 5),
                        TableCol('Sent to', flex: 2),
                        TableCol('When', flex: 1),
                        TableCol('', width: 48),
                      ],
                      rowCount: visible.length,
                      empty: const EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No notifications',
                      ),
                      rowBuilder: (i) {
                        final n = visible[i];
                        final recipient = n.sentTo == null
                            ? null
                            : users.allUsers.firstWhereOrNull((u) => u.id == n.sentTo);
                        return [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(n.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AdminText.muted),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: n.sentTo == null
                                ? const StatusChip('Everyone', tone: Tone.brand, icon: Icons.public_rounded)
                                : Text(
                                    recipient == null
                                        ? 'One reader'
                                        : (recipient.name.isEmpty ? recipient.email : recipient.name),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          Text(relativeTime(n.createdAt), style: AdminText.muted),
                          _deleting.contains(n.id)
                              ? const Center(
                                  child: SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2)))
                              : IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(n),
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: Palette.danger, size: 20),
                                ),
                        ];
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
