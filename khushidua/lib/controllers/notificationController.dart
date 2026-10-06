import 'package:get/get.dart';
import 'package:khushidua/services/notificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notificationModel.dart';

class NotificationController extends GetxController {
  static const _kLastSeen = 'inboxLastSeenMillis';
  static const _kClearedAt = 'inboxClearedAtMillis';
  static const _kDeleted = 'inboxDeletedIds';

  final List<NotificationModel> _allNotifications = [];

  /// When the inbox was last opened; anything newer counts as unread.
  DateTime? _lastSeen;

  /// "Clear All" hides everything up to this moment. Kept in preferences, not
  /// just memory, so cleared notifications stay cleared after a restart.
  DateTime? _clearedAt;

  /// Notifications the user deleted one by one. Hidden on this device only:
  /// broadcasts are shared by every user, so the document itself stays.
  final Set<String> _deletedIds = {};

  /// Newest first, without the ones the user cleared or deleted.
  List<NotificationModel> get allNotifications {
    final clearedAt = _clearedAt;
    return _allNotifications
        .where(
          (n) =>
              !_deletedIds.contains(n.id) &&
              (clearedAt == null || n.createdAt.isAfter(clearedAt)),
        )
        .toList();
  }

  /// Shown as the badge on the home screen's bell.
  int get unreadCount {
    final lastSeen = _lastSeen;
    if (lastSeen == null) return 0;
    return allNotifications.where((n) => n.createdAt.isAfter(lastSeen)).length;
  }

  @override
  void onInit() {
    super.onInit();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getInt(_kLastSeen);
    final clearedAt = prefs.getInt(_kClearedAt);
    if (lastSeen == null) {
      // A first launch starts with nothing unread, rather than a badge
      // counting every announcement ever sent.
      _lastSeen = DateTime.now();
      await prefs.setInt(_kLastSeen, _lastSeen!.millisecondsSinceEpoch);
    } else {
      _lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    }
    if (clearedAt != null) {
      _clearedAt = DateTime.fromMillisecondsSinceEpoch(clearedAt);
    }
    _deletedIds.addAll(prefs.getStringList(_kDeleted) ?? const []);
    update();
  }

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

  /// Called when the inbox is opened.
  Future<void> markAllSeen() async {
    _lastSeen = DateTime.now();
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSeen, _lastSeen!.millisecondsSinceEpoch);
  }

  Future<void> deleteNotification(String id) async {
    if (!_deletedIds.add(id)) return;
    update();
    final prefs = await SharedPreferences.getInstance();
    // Only ids still in the inbox are worth remembering, so the list does not
    // grow forever.
    final live = _allNotifications.map((n) => n.id).toSet();
    await prefs.setStringList(
      _kDeleted,
      _deletedIds.where(live.contains).toList(),
    );
  }

  Future<void> clearNotifications() async {
    _clearedAt = DateTime.now();
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kClearedAt, _clearedAt!.millisecondsSinceEpoch);
  }
}
