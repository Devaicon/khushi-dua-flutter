import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/notificationController.dart';
import 'package:khushidua/views/subScreens/home.dart';
import 'package:khushidua/views/subScreens/notifications.dart';
import 'package:khushidua/views/subScreens/prayer.dart';
import 'package:khushidua/views/subScreens/search.dart';
import 'package:khushidua/views/subScreens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../constants/userData.dart';
import '../controllers/themeController.dart';
import '../controllers/userController.dart';
import '../helpers/adHelper.dart';
import '../services/adService.dart';
import '../services/contentRepository.dart';
import '../services/pushService.dart';
import '../services/reminderService.dart';
import 'subScreens/categoryDetailScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  /// Slides the incoming tab in from the side it sits on in the navbar:
  /// from the right when moving to a later tab, from the left for an earlier one.
  late final AnimationController _tabSwitch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _tabSwitchCurve = CurvedAnimation(
    parent: _tabSwitch,
    curve: AppMotion.curve,
  );
  double _slideFrom = 0;
  final Map<int, bool> _screenInitialized = {0: true};

  Widget _getScreen(int index) {
    if (_screenInitialized[index] != true) {
      _screenInitialized[index] = true;
    }
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const PrayerScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return const NotificationScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  /// The age group the current banner was requested for; null when none is.
  int? _adAgeGroup;
  VoidCallback? _stopWatchingAgeGroup;

  @override
  void dispose() {
    _stopWatchingAgeGroup?.call();
    _tabSwitch.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Keeps the banner in step with the age group: none at all for little
  /// kids, and a fresh request whenever the audience changes, since older
  /// kids and grown ups are configured differently.
  Future<void> _syncBannerAd() async {
    final ageGroup = Get.find<ThemeController>().selectedAgeGroup;
    final wanted = AdService.allowsAds(ageGroup) ? ageGroup : null;
    if (wanted == _adAgeGroup) return;
    _adAgeGroup = wanted;

    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) setState(() => _isAdLoaded = false);
    if (wanted == null) return;

    await AdService.prepare(wanted);
    // The age group may have changed again while AdMob was starting.
    if (!mounted || _adAgeGroup != wanted) return;

    final ad = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted || _bannerAd != loaded) return;
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
          if (_bannerAd == ad) _bannerAd = null;
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    setState(() {
      // _selectedScreen = _screens[0]; // Removed for lazy loading
    });
    ContentRepository.instance.load();
    Get.find<NotificationController>().getAllNotifications();
    _wireNotificationTaps();

    _stopWatchingAgeGroup = Get.find<ThemeController>().addListener(
      _syncBannerAd,
    );
    _syncBannerAd();
  }

  static const int _homeTab = 0;
  static const int _prayerTab = 1;
  static const int _inboxTab = 3;

  /// Routes taps on reminders and pushes. Nothing consumed them before, so a
  /// tap only ever opened the app wherever it last was.
  void _wireNotificationTaps() {
    PushService.instance.onOpenInbox = () => _goToTab(_inboxTab);
    ReminderService.instance.onNotificationTap = _handlePayload;

    final pending = ReminderService.instance.pendingPayload;
    ReminderService.instance.pendingPayload = null;
    if (pending != null) {
      // After the first frame, so the tabs exist to switch to.
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePayload(pending));
    }

    PushService.instance.start();
  }

  void _handlePayload(String payload) {
    if (payload == 'inbox') {
      _goToTab(_inboxTab);
    } else if (payload.startsWith('salah:')) {
      _goToTab(_prayerTab);
    } else if (payload.startsWith('azkar:')) {
      _goToTab(_homeTab);
      _openCategory(payload.substring('azkar:'.length));
    }
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
    Get.to(() => CategoryDetailScreen(matches.first, rbluedark));
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
    if (_selectedIndex != index) {
      setState(() {
        _slideFrom = index > _selectedIndex ? 0.08 : -0.08;
        _screenInitialized[index] = true;
        _selectedIndex = index;
      });
      _tabSwitch.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: GetBuilder<UserController>(
        builder: (userController) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabSwitchCurve,
                    builder: (context, child) {
                      final t = _tabSwitchCurve.value;
                      return FractionalTranslation(
                        translation: Offset(_slideFrom * (1 - t), 0),
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    // IndexedStack keeps every visited tab alive, so its
                    // scroll position and state survive the animation.
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: List.generate(5, (index) {
                        return _screenInitialized[index] == true
                            ? _getScreen(index)
                            : const SizedBox.shrink();
                      }),
                    ),
                  ),
                ),
                if (userController.userModel == null ||
                    (!userController.userModel!.isMember) ||
                    userController.userModel!.isBlocked)
                  if (_isAdLoaded && _bannerAd != null)
                    Container(
                      alignment: Alignment.center,
                      width: _bannerAd!.size.width.toDouble(),
                      height: 80,
                      child: AdWidget(ad: _bannerAd!),
                    ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  /// Hand-rolled rather than a BottomNavigationBar: no ink splash, no
  /// competing elevation, and a highlight that slides between tabs.
  static const List<String> _navIcons = [
    "assets/images/home.png",
    "assets/images/prayer.png",
    "assets/images/search.png",
    "assets/images/notification.png",
    "assets/images/settings.png",
  ];

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildNavItem(String asset, int index) {
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
            color: isSelected
                ? rbluedark.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: AppRadius.pillAll,
          ),
          child: AnimatedScale(
            duration: AppMotion.base,
            curve: AppMotion.curve,
            scale: isSelected ? 1.1 : 1.0,
            child: Image.asset(
              asset,
              width: 24,
              height: 24,
              color: isSelected ? rbluedark : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
