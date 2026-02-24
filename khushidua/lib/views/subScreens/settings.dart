import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../controllers/userController.dart';
import '../../models/settingsModel.dart';
import '../auth/signupScreen.dart';
import '../subSettings/languageSettings.dart';
import '../subSettings/audioDownloadSettings.dart';
import '../../widgets/profileAvatar.dart';
import '../../widgets/customSnackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<SettingsModel> settingsList = [
    SettingsModel(
      title: "Account",
      subTitle: "Profile settings",
      icon: Icons.person_2_outlined,
    ),
    SettingsModel(
      title: "Downloads",
      subTitle: "Audio Downloads",
      icon: Icons.download,
    ),
    SettingsModel(
      title: "Language",
      subTitle: "Change app language",
      icon: Icons.language,
    ),
    SettingsModel(
      title: "Share",
      subTitle: "Share with friends",
      icon: Icons.share,
    ),
    SettingsModel(
      title: "Premium",
      subTitle: "Unlock all features",
      icon: Icons.workspace_premium,
    ),
  ];

  void accountSettings() {
    if (Get.find<UserController>().isLoggedIn) {
      // Show account settings dialog
      Get.dialog(
        AlertDialog(
          title: Text('Account Settings', style: TextStyle(color: rbluedark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${Get.find<UserController>().userName}'),
              SizedBox(height: 8),
              Text(
                'Email: ${Get.find<UserController>().userModel?.email ?? "N/A"}',
              ),
              SizedBox(height: 8),
              Text('Points: ${Get.find<UserController>().points}'),
              SizedBox(height: 8),
              Text(
                'Member: ${(Get.find<UserController>().userModel?.isMember ?? false) ? "Yes" : "No"}',
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Close')),
            TextButton(
              onPressed: () async {
                Get.back();
                // Logout functionality
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                await prefs.remove('userId');
                Get.find<UserController>().setLoggedIn(false);
                CustomSnackbar.show(
                  "Logged Out",
                  "You have been logged out successfully",
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      CustomSnackbar.show(
        "Not logged in",
        "Please login to your account.",
        isSuccess: false,
      );
      // Navigate to signup
      Get.to(() => const SignupScreen(), transition: Transition.fade);
    }
  }

  void downloadSettings() {
    Get.to(const AudioDownloadSettings(), transition: Transition.fade);
  }

  void languageSettings() {
    Get.to(const LanguageSettings(), transition: Transition.fade);
  }

  void premiumSettings() {
    // Get.to(PremiumSettings(), transition: Transition.fade);
  }

  void shareApp() async {
    try {
      // For iOS, use a placeholder until app is published on App Store
      String appUrl;
      String shareMessage;

      if (Platform.isIOS) {
        // Replace with actual App Store link when published
        appUrl = 'https://apps.apple.com/app/khushi-dua';
        shareMessage =
            'Check out Khushi Dua - Islamic Learning App\n\n'
            '📿 Read beautiful Islamic Duas\n'
            '🕋 Find Qibla direction\n'
            '⏰ Prayer times\n\n'
            'Coming soon on App Store!\n'
            '$appUrl';
      } else {
        appUrl =
            'https://play.google.com/store/apps/details?id=com.nauman7888.khushiiduaapp';
        shareMessage =
            'Check out Khushi Dua - Islamic Learning App\n\n'
            '📿 Read beautiful Islamic Duas\n'
            '🕋 Find Qibla direction\n'
            '⏰ Prayer times\n\n'
            'Download now:\n'
            '$appUrl';
      }

      debugPrint("Attempting to share app...");

      final result = await Share.share(
        shareMessage,
        subject: 'Khushi Dua - Islamic Learning App',
      );

      debugPrint('Share result: ${result.status}');

      if (result.status == ShareResultStatus.success) {
        CustomSnackbar.show(
          'Success',
          'Thank you for sharing!',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
      CustomSnackbar.show(
        'Error',
        'Failed to share app. Please try again.',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<VoidCallback> functionsList = [
      accountSettings,
      downloadSettings,
      languageSettings,
      shareApp,
      premiumSettings,
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FE),
      body: GetBuilder<UserController>(
        builder: (userController) {
          return CustomScrollView(
            slivers: [
              // Premium Profile Header
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                backgroundColor: rbluedark,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        FadeInAnimationTTB(
                          delay: 1,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              InkWell(
                                onTap: _showAvatarPopup,
                                child: const ProfileAvatar(
                                  size: 100,
                                  showBorder: true,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: rbluedark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInAnimationBTT(
                          delay: 1,
                          child: Column(
                            children: [
                              Text(
                                userController.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: rbluedark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (userController.isLoggedIn &&
                                  (userController.userModel?.isMember ?? false))
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.stars_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "PREMIUM MEMBER".tr,
                                        style: const TextStyle(
                                          color: rbluedark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard(
                              "Points".tr,
                              userController.points.toString(),
                              Icons.emoji_events_rounded,
                            ),
                            const SizedBox(width: 15),
                            _buildStatCard(
                              "Duas Read".tr,
                              (userController.userModel?.readDuas.length ?? 0)
                                  .toString(),
                              Icons.menu_book_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Settings Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionTitle("PREFERENCES".tr),
                      SettingTile(settingsList[0], functionsList[0]),
                      SettingTile(settingsList[1], functionsList[1]),
                      SettingTile(settingsList[2], functionsList[2]),

                      const SizedBox(height: 20),
                      _buildSectionTitle("SUPPORT".tr),
                      SettingTile(settingsList[3], functionsList[3]),
                      if (!userController.isLoggedIn ||
                          !(userController.userModel?.isMember ?? false))
                        SettingTile(settingsList[4], functionsList[4]),

                      const SizedBox(height: 30),

                      // Logout / Login Button
                      InkWell(
                        onTap: () async {
                          if (userController.isLoggedIn) {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            userController.setLoggedIn(false);
                            Get.find<UserController>().setUserName(
                              "Guest User",
                            );
                            Get.find<UserController>().setPoints(0);
                            CustomSnackbar.show(
                              "Success",
                              "Logged out successfully".tr,
                            );
                          } else {
                            Get.to(
                              () => const SignupScreen(),
                              transition: Transition.downToUp,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: userController.isLoggedIn
                                ? Colors.red.withOpacity(0.08)
                                : Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: userController.isLoggedIn
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                userController.isLoggedIn
                                    ? Icons.logout_rounded
                                    : Icons.login_rounded,
                                color: userController.isLoggedIn
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                userController.isLoggedIn
                                    ? "Logout Account".tr
                                    : "Sign In / Sign Up".tr,
                                style: TextStyle(
                                  color: userController.isLoggedIn
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          "Version 1.0.2".tr,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: rbluedark, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: rbluedark,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: rbluedark.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: rbluedark.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _showAvatarPopup() async {
    String? avatarPath = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Select Your Avatar".tr),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _avatarOption(context, "assets/images/male.png"),
              _avatarOption(context, "assets/images/female.png"),
            ],
          ),
        );
      },
    );

    if (avatarPath != null) {
      Get.find<UserController>().setAvatar(avatarPath);
    }
  }

  Widget _avatarOption(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, imagePath); // Return selected image path
      },
      child: Image.asset(imagePath, width: 80, height: 80),
    );
  }
}

class SettingTile extends StatelessWidget {
  final SettingsModel _settingsModel;
  final VoidCallback function;

  const SettingTile(this._settingsModel, this.function, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: function,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rbluedark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_settingsModel.icon, color: rbluedark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settingsModel.title.tr,
                    style: const TextStyle(
                      color: rbluedark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_settingsModel.subTitle.isNotEmpty)
                    Text(
                      _settingsModel.subTitle.tr,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
