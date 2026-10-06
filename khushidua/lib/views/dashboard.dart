import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/notificationController.dart';
import 'package:khushidua/views/subScreens/home.dart';
import 'package:khushidua/views/subScreens/notifications.dart';
import 'package:khushidua/views/qiblaTab.dart';
import 'package:khushidua/views/subScreens/prayer.dart';
import 'package:khushidua/views/subScreens/search.dart';
import 'package:khushidua/views/subScreens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../constants/userData.dart';
import '../controllers/userController.dart';
import '../services/contentRepository.dart';
import '../services/pushService.dart';
import '../services/reminderService.dart';
import '../widgets/donateCard.dart';
import 'subScreens/categoryDetailScreen.dart';

/// The dashboard's tabs, in navbar order, and a way for a screen inside one
/// tab to switch to another (the prayer screen's compass button opens Qibla).
abstract final class AppTabs {
  static const int home = 0;
  static const int prayer = 1;
  static const int search = 2;
  static const int qibla = 3;
  static const int settings = 4;
  static const int count = 5;

  static void Function(int index)? _goTo;

  static void go(int index) => _goTo?.call(index);
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = AppTabs.home;

  /// Swiping left or right moves between neighbouring tabs. Pages are built
  /// the first time they are shown, not all at start-up.
  final PageController _pages = PageController();

  Widget _buildPage(int index) {
    switch (index) {
      case AppTabs.prayer:
        return const _KeepAlive(child: PrayerScreen());
      case AppTabs.search:
        return const _KeepAlive(child: SearchScreen());
      case AppTabs.qibla:
        // Not kept alive: the compass and location sensors should stop as
        // soon as the reader leaves the tab.
        return const QiblaTab();
      case AppTabs.settings:
        return const _KeepAlive(child: SettingsScreen());
      default:
        return const _KeepAlive(child: HomeScreen());
    }
  }

  @override
  void dispose() {
    AppTabs._goTo = null;
    _pages.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AppTabs._goTo = _goToTab;
    getSharedPrefs();
    ContentRepository.instance.load();
    Get.find<NotificationController>().getAllNotifications();
    _wireNotificationTaps();
  }

  /// Routes taps on reminders and pushes. Nothing consumed them before, so a
  /// tap only ever opened the app wherever it last was.
  void _wireNotificationTaps() {
    PushService.instance.onOpenInbox = _openInbox;
    ReminderService.instance.onNotificationTap = _handlePayload;

    final pending = ReminderService.instance.pendingPayload;
    ReminderService.instance.pendingPayload = null;
    if (pending != null) {
      // After the first frame, so the tabs exist to switch to.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handlePayload(pending),
      );
    }

    PushService.instance.start();
  }

  void _handlePayload(String payload) {
    if (payload == 'inbox') {
      _openInbox();
    } else if (payload == 'donate') {
      _goToTab(AppTabs.home);
      openDonate();
    } else if (payload.startsWith('salah:')) {
      _goToTab(AppTabs.prayer);
    } else if (payload.startsWith('azkar:')) {
      _goToTab(AppTabs.home);
      _openCategory(payload.substring('azkar:'.length));
    }
  }

  /// The inbox is no longer a tab; it opens over the home screen.
  void _openInbox() {
    _goToTab(AppTabs.home);
    Get.to(() => const NotificationScreen());
  }

  void _goToTab(int index) {
    if (!mounted) return;
    Get.until((route) => route.isFirst);
    _onItemTapped(index);
  }

  void _openCategory(String categoryId) {
    final matches = Get.find<CategoryController>().allCategories.where(
      (c) => c.id == categoryId,
    );
    if (matches.isEmpty) return;
    Get.to(() => CategoryDetailScreen(matches.first, kBrandNavy));
  }

  getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = await prefs.getString("userId") ?? "";

    if (userId != "") {
      Get.find<UserController>().getUserData(userId);
    } else {
      isLoggedIn = await prefs.getBool("isLoggedIn") ?? false;
      points = await prefs.getInt("userPoints") ?? 0;
      userName = await prefs.getString("userName") ?? "Guest User";
      avatar = await prefs.getString("userAvatar") ?? "";
      Get.find<UserController>().setUserName(userName);
      Get.find<UserController>().setLoggedIn(false);
      Get.find<UserController>().setPoints(points);
      Get.find<UserController>().setAvatar(avatar);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex || !_pages.hasClients) return;
    setState(() => _selectedIndex = index);
    // A neighbour slides in as a swipe would. A distant tab jumps, so the
    // tabs in between are not built just to be scrolled past.
    if ((index - (_pages.page ?? _selectedIndex)).abs() <= 1) {
      _pages.animateToPage(
        index,
        duration: AppMotion.slow,
        curve: AppMotion.curve,
      );
    } else {
      _pages.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: SafeArea(
        child: PageView.builder(
          controller: _pages,
          itemCount: AppTabs.count,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemBuilder: (context, index) => _buildPage(index),
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  /// Hand-rolled rather than a BottomNavigationBar: no ink splash, no
  /// competing elevation, and a highlight that slides between tabs.
  ///
  /// Duas shows the raised hands and Prayer the mosque; the two images used to
  /// be the other way round.
  static const List<Object> _navIcons = [
    "assets/images/prayer.png",
    "assets/images/home.png",
    "assets/images/search.png",
    Icons.explore_rounded,
    "assets/images/settings.png",
  ];

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppSurface.card,
        boxShadow: AppElevation.raised,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < _navIcons.length; i++)
                Expanded(child: _buildNavItem(_navIcons[i], i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(Object icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Center(
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? AppSpace.xl : AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? brandFill : Colors.transparent,
            borderRadius: AppRadius.pillAll,
          ),
          child: AnimatedScale(
            duration: AppMotion.base,
            curve: AppMotion.curve,
            scale: isSelected ? 1.1 : 1.0,
            // Every tab is drawn in full brand ink — any muted or grey tint
            // read as disabled. The selected one inverts to white on a solid
            // pill instead.
            child: icon is IconData
                ? Icon(
                    icon,
                    size: 26,
                    color: isSelected ? Colors.white : rbluedark,
                  )
                : Image.asset(
                    icon as String,
                    width: 24,
                    height: 24,
                    color: isSelected ? Colors.white : rbluedark,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Keeps a tab's state — scroll position, loaded data — while another tab is
/// showing, as the IndexedStack this PageView replaced did.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
