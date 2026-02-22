import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/categoryController.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/controllers/notificationController.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/views/tabs/categories.dart';
import 'package:khushiduaadmin/views/tabs/duas.dart';
import 'package:khushiduaadmin/views/tabs/home.dart';
import 'package:khushiduaadmin/views/tabs/notifications.dart';
import 'package:khushiduaadmin/views/tabs/profile.dart';
import 'package:khushiduaadmin/views/tabs/users.dart';
import 'package:khushiduaadmin/views/tabs/mlSettings.dart';
import 'dart:html' as html;
import '../constants/colors.dart';
import '../controllers/authController.dart';
import 'auth/login.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    CategoriesTab(),
    UsersTab(),
    DuasTab(),
    NotificationTab(),
    ProfileTab(),
    MLSettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final authController = Get.find<AuthController>();
    final categoryController = Get.find<CategoryController>();
    final duaController = Get.find<DuaController>();
    final userController = Get.find<UserController>();
    final notificationController = Get.find<NotificationController>();

    await authController.getAdminDetails();
    categoryController.getAllCategories();
    categoryController.getAllSubCategories();
    duaController.getAllDuas();
    userController.getAllUsers();
    notificationController.getAllNotifications();
  }

  void _onTabSelected(int index) {
    if (index == 8) {
      // Logout
      showLogOutPopup();
      return;
    }
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab > 6
                  ? 0
                  : _selectedTab, // Fallback for logout tab index
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Sidebar build to keep build method clean
  Widget _buildSidebar() {
    final sidebarWidth = MediaQuery.of(context).size.width * 0.16;
    return SizedBox(
      width: sidebarWidth,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildSidebarHeader(),
                _buildSidebarItem(0, 'Dashboard', 'assets/svgs/dashboard.svg'),
                _buildSidebarItem(1, 'Categories', 'assets/svgs/coins.svg'),
                _buildSidebarItem(3, 'Duas', 'assets/svgs/ad.svg'),
                _buildSidebarItem(2, 'Users', 'assets/svgs/users.svg'),
                _buildSidebarItem(4, 'Notifications', null,
                    iconData: Icons.notifications_active_outlined),
              ],
            ),
          ),
          Column(
            children: [
              _buildSidebarItem(5, 'Profile', 'assets/svgs/user.svg'),
              _buildSidebarItem(6, 'ML Settings', null,
                  iconData: Icons.settings_applications),
              _buildSidebarItem(8, 'Logout', 'assets/svgs/logout.svg',
                  isLogout: true),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Khushi Dua Admin",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: rWhite),
          ),
          const SizedBox(width: 8),
          Image.asset("assets/images/logo.png", width: 30, height: 30),
        ],
      ),
    ).marginSymmetric(vertical: 20);
  }

  Widget _buildSidebarItem(int index, String title, String? svgPath,
      {IconData? iconData, bool isLogout = false}) {
    bool isSelected = _selectedTab == index;
    Color color = isSelected ? rWhite : rHint;
    Color bgColor = isSelected ? rGreen : Colors.transparent;

    return ListTile(
      tileColor: bgColor,
      leading: svgPath != null
          ? SvgPicture.asset(svgPath, color: color, width: 20)
          : Icon(iconData, color: color, size: 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (!isLogout) Icon(Icons.arrow_forward_ios, color: color, size: 12),
        ],
      ),
      onTap: () => _onTabSelected(index),
    );
  }

  showLogOutPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ElasticIn(
          child: AlertDialog(
            backgroundColor: rBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
                child: Text("Are you sure?",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: rWhite))),
            content: const Text(
              "You want to Logout",
              style: TextStyle(fontSize: 16, color: rWhite),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: rGreen),
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            rGreen.withOpacity(0.22),
                            rGreen.withOpacity(0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text("Cancel",
                          style: TextStyle(
                              color: rWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      html.window.localStorage.remove('adminId');
                      Get.off(const LoginScreen(), transition: Transition.fade);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: rRed),
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            rRed,
                            rRed,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text("Logout",
                          style: TextStyle(
                              color: rWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            actionsAlignment: MainAxisAlignment.center,
          ),
        );
      },
    );
  }
}
