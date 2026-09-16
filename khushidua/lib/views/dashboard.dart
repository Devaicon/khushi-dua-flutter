import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/duaController.dart';
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
import '../controllers/userController.dart';
import '../helpers/adHelper.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    setState(() {
      // _selectedScreen = _screens[0]; // Removed for lazy loading
    });
    Get.find<CategoryController>().getAllCategories();
    Get.find<CategoryController>().getAllSubCategories();
    Get.find<DuaController>().getAllDuas();
    Get.find<NotificationController>().getAllNotifications();

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
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
      if (_screenInitialized[index] != true) {
        setState(() {
          _screenInitialized[index] = true;
          _selectedIndex = index;
        });
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
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
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(5, (index) {
                      return _screenInitialized[index] == true
                          ? _getScreen(index)
                          : const SizedBox.shrink();
                    }),
                  ),
                ),
                if (userController.userModel == null ||
                    (!userController.userModel!.isMember) ||
                    userController.userModel!.isBlocked)
                  if (_isAdLoaded)
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
