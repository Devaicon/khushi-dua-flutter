import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/notificationController.dart';
import '../../controllers/userController.dart';
import '../../models/userModel.dart';
import '../../search/adminSearch.dart';
import '../../services/userService.dart';
import '../../widgets/adminSearchField.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';

enum _UserFilter { all, members, blocked, readers }

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _query = '';
  _UserFilter _filter = _UserFilter.all;

  bool _matches(UserModel u) => switch (_filter) {
        _UserFilter.all => true,
        _UserFilter.members => u.isMember,
        _UserFilter.blocked => u.isBlocked,
        _UserFilter.readers => u.readDuas.isNotEmpty,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<UserController>(
        builder: (c) {
          final users = c.allUsers;
          final visible = filterBySearch(
              [for (final u in users) if (_matches(u)) u], _query, userSearchFields);
          final members = users.where((u) => u.isMember).length;
          final blocked = users.where((u) => u.isBlocked).length;
          final readers = users.where((u) => u.readDuas.isNotEmpty).length;

          return AdminPage(
            scroll: false,
            title: 'Users',
            subtitle: '${formatCount(users.length)} signed-up readers · '
                '$members members · $blocked blocked',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdminSearchField(
                        hint: 'Search by name, email or id',
                        matchCount: visible.length,
                        totalCount: users.length,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    SegmentedButton<_UserFilter>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: _UserFilter.all, label: Text('All ${users.length}')),
                        ButtonSegment(value: _UserFilter.readers, label: Text('Listening $readers')),
                        ButtonSegment(value: _UserFilter.members, label: Text('Members $members')),
                        ButtonSegment(value: _UserFilter.blocked, label: Text('Blocked $blocked')),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) => setState(() => _filter = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                Expanded(
                  child: AdminTable(
                    columns: const [
                      TableCol('Reader', flex: 4),
                      TableCol('Joined', flex: 2),
                      TableCol('Listened', flex: 1),
                      TableCol('Points', flex: 1),
                      TableCol('Membership', width: 120),
                      TableCol('Status', width: 100),
                      TableCol('', width: 48),
                    ],
                    rowCount: visible.length,
                    empty: EmptyState(
                      icon: Icons.person_search_outlined,
                      title: c.loaded ? 'No users match' : 'Loading users…',
                    ),
                    rowBuilder: (i) {
                      final u = visible[i];
                      return [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Palette.brandSoft,
                              child: Text(
                                (u.name.isNotEmpty ? u.name : u.email).characters.firstOrNull?.toUpperCase() ?? '?',
                                style: const TextStyle(color: Palette.brand, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name.isEmpty ? '(no name)' : u.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(u.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AdminText.muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(relativeTime(u.createdAt), style: AdminText.muted),
                        Text('${u.readDuas.length}'),
                        Text(formatCount(u.points)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: u.isMember
                              ? const StatusChip('Member', tone: Tone.brand, icon: Icons.star_rounded)
                              : const Text('Free', style: AdminText.muted),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusChip(u.isBlocked ? 'Blocked' : 'Active',
                              tone: u.isBlocked ? Tone.danger : Tone.success),
                        ),
                        _actions(u),
                      ];
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actions(UserModel u) {
    final name = u.name.isEmpty ? u.email : u.name;
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) async {
        try {
          switch (action) {
            case 'member':
              if (await confirmAction(context,
                  title: u.isMember ? 'End membership?' : 'Make a member?',
                  message: u.isMember
                      ? '$name loses member features and is notified.'
                      : '$name gets member features and is notified.',
                  confirmLabel: u.isMember ? 'End membership' : 'Make member')) {
                await UserService().setMember(u, !u.isMember);
                CustomSnackbar.show('Saved', u.isMember ? 'Membership ended.' : 'Membership granted.');
              }
            case 'block':
              if (await confirmAction(context,
                  title: u.isBlocked ? 'Unblock $name?' : 'Block $name?',
                  message: u.isBlocked
                      ? 'They can use the app again and are notified.'
                      : 'They are signed out of the app and notified.',
                  confirmLabel: u.isBlocked ? 'Unblock' : 'Block',
                  danger: !u.isBlocked)) {
                await UserService().setBlocked(u, !u.isBlocked);
                CustomSnackbar.show('Saved', u.isBlocked ? 'User unblocked.' : 'User blocked.');
              }
            case 'message':
              if (mounted) await showMessageDialog(context, user: u);
          }
        } catch (e) {
          CustomSnackbar.show("Couldn't update $name", '$e', isSuccess: false);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'message',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.send_outlined),
            title: Text('Send a notification'),
          ),
        ),
        PopupMenuItem(
          value: 'member',
          child: ListTile(
            dense: true,
            leading: Icon(u.isMember ? Icons.star_outline_rounded : Icons.star_rounded),
            title: Text(u.isMember ? 'End membership' : 'Make member'),
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: ListTile(
            dense: true,
            leading: Icon(u.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: u.isBlocked ? null : Palette.danger),
            title: Text(u.isBlocked ? 'Unblock' : 'Block',
                style: TextStyle(color: u.isBlocked ? null : Palette.danger)),
          ),
        ),
      ],
    );
  }
}

/// Writes and sends a notification, to everyone or to one [user], with a
/// preview of how it lands on a phone.
Future<void> showMessageDialog(BuildContext context, {UserModel? user}) {
  return showDialog(context: context, builder: (_) => _MessageDialog(user: user));
}

class _MessageDialog extends StatefulWidget {
  const _MessageDialog({this.user});
  final UserModel? user;

  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = widget.user;
    if (user == null &&
        !await confirmAction(context,
            title: 'Send to everyone?',
            message: 'Every reader with the app installed gets this on their '
                'phone, and it stays in the app\'s notifications list.',
            confirmLabel: 'Send to everyone')) {
      return;
    }
    setState(() => _sending = true);
    final n = Get.find<NotificationController>();
    if (user == null) {
      await n.sendGlobalNotification(_title.text.trim(), _message.text.trim());
    } else {
      await n.sendIndividualNotification(user, _title.text.trim(), _message.text.trim());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _title.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;
    final to = widget.user == null
        ? 'every reader'
        : (widget.user!.name.isEmpty ? widget.user!.email : widget.user!.name);
    return AlertDialog(
      title: Text('Notify $to'),
      content: SizedBox(
        width: 720,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _title,
                    maxLength: 65,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: Space.sm),
                  TextField(
                    controller: _message,
                    maxLines: 5,
                    maxLength: 240,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xl),
            SizedBox(width: 260, child: NotificationPreview(title: _title.text, message: _message.text)),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      actions: [
        AdminButton.ghost(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        AdminButton(
          label: 'Send',
          icon: Icons.send_rounded,
          busy: _sending,
          onPressed: ready ? _send : null,
        ),
      ],
    );
  }
}

/// A notification as it appears on a phone's lock screen.
class NotificationPreview extends StatelessWidget {
  const NotificationPreview({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('PREVIEW', style: AdminText.label),
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/logo.png', width: 22, height: 22),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.trim().isEmpty ? 'Title' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(message.trim().isEmpty ? 'Your message' : message,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
