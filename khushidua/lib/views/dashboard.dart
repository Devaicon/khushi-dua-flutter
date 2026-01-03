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

import '../constants/userData.dart';
import '../controllers/userController.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  Widget _selectedScreen = Container();

  final List<Widget> _screens = [
    HomeScreen(),
    PrayerScreen(),
    SettingsScreen(),
    SearchScreen(),
    NotificationScreen(),
  ];

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
      _selectedScreen = _screens[0];
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
    setState(() {
      _selectedIndex = index;
      _selectedScreen = _screens[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GetBuilder<UserController>(
        builder: (userController) {
          return Column(
            children: [
              Expanded(child: _selectedScreen),
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
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(0),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset("assets/images/prayer.png"),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(1),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset("assets/images/home.png"),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(2),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset("assets/images/settings.png"),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(3),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset(
                "assets/images/search.png",
                width: 30,
                height: 30,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(4),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Image.asset(
                "assets/images/notification.png",
                width: 30,
                height: 30,
              ),
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        // onTap: _onItemTapped,
      ),
    );
  }
}
