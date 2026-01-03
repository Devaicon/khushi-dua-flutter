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
import '../constants/userData.dart';
import '../controllers/userController.dart';

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
      adUnitId: "ca-app-pub-3940256099942544/6300978111",
      size: AdSize.banner,
      request: AdRequest(),
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
      backgroundColor: Colors.white,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _buildNavItem("assets/images/home.png", 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavItem("assets/images/prayer.png", 1),
              label: 'Prayer',
            ),
            BottomNavigationBarItem(
              icon: _buildNavItem("assets/images/search.png", 2),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _buildNavItem("assets/images/notification.png", 3),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: _buildNavItem("assets/images/settings.png", 4),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildNavItem(String asset, int index) {
    bool isSelected = _selectedIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? rbluedark.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            asset,
            width: isSelected ? 28 : 24,
            height: isSelected ? 28 : 24,
            color: isSelected ? rbluedark : Colors.grey,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: rbluedark, shape: BoxShape.circle),
          ),
      ],
    );
  }
}
