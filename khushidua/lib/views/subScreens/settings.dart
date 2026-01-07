import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/userData.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../models/settingsModel.dart';
import '../auth/signupScreen.dart';
import '../subSettings/languageSettings.dart';
import '../subSettings/audioDownloadSettings.dart';

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
    SettingsModel(title: "Language", subTitle: "", icon: Icons.language),
    SettingsModel(title: "Share", subTitle: "Share App", icon: Icons.share),
    SettingsModel(
      title: "Premium",
      subTitle: "Premium Account",
      icon: Icons.workspace_premium,
    ),
  ];

  accountSettings() {
    if (Get.find<UserController>().isLoggedIn) {
      // Get.to(AccountSettings(), transition: Transition.fade);
    } else {
      Get.snackbar(
        colorText: Colors.white,
        "Not logged in",
        "You are not logged in currently. Please login to your account.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> downloadSettings() async {
    Get.to(const AudioDownloadSettings(), transition: Transition.fade);
  }

  languageSettings() {
    Get.to(LanguageSettings(), transition: Transition.fade);
  }

  premiumSettings() {
    // Get.to(PremiumSettings(), transition: Transition.fade);
  }

  shareApp() {
    Share.share(
      'https://play.google.com/store/apps/details?id=com.nauman7888.khushiiduaapp',
      subject: 'My Islamic Learning App',
    );
  }

  about() {
    // Get.to(AboutScreen(), transition: Transition.fade);
  }

  List<String> fileNames = [];
  bool isCopying = false;

  @override
  Widget build(BuildContext context) {
    List functionsList = [
      accountSettings,
      downloadSettings,
      languageSettings,
      shareApp,
      premiumSettings,
      about,
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: rwhite,
        body: SingleChildScrollView(
          child: GetBuilder<UserController>(
            builder: (userController) {
              return GetBuilder<ThemeController>(
                builder: (themeController) {
                  return Column(
                    children: [
                      Material(
                        elevation: 8,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 200,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: GetBuilder<UserController>(
                            builder: (userController) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeInAnimationTTB(
                                    delay: 1,
                                    child: InkWell(
                                      onTap: _showAvatarPopup,
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                          shape: BoxShape.circle,
                                        ),
                                        child: userController.avatar != ""
                                            ? ClipOval(
                                                child: Image.asset(
                                                  userController.avatar,
                                                ),
                                              )
                                            : SizedBox(),
                                      ),
                                    ),
                                  ),
                                  FadeInAnimationBTT(
                                    delay: 1,
                                    child: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: rbluedark,
                                        letterSpacing: 0.5,
                                      ),
                                    ).marginOnly(top: 12),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      FadeInAnimationTTB(
                        delay: 1,
                        child: Column(
                          children: List.generate(settingsList.length, (index) {
                            if (index == 4) {
                              if (userController.isLoggedIn &&
                                  userController.userModel!.isMember) {
                                return const SizedBox.shrink();
                              }
                            }
                            return SettingTile(
                              settingsList[index],
                              functionsList[index],
                            );
                          }),
                        ).marginOnly(top: 12),
                      ),
                      GetBuilder<UserController>(
                        builder: (userController) {
                          return InkWell(
                            onTap: () async {
                              if (userController.isLoggedIn) {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.clear();
                                userController.setLoggedIn(false);
                                Get.find<UserController>().setUserName("");
                                Get.find<UserController>().setPoints(0);
                              } else {
                                Get.to(
                                  SignupScreen(),
                                  transition: Transition.downToUp,
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: userController.isLoggedIn
                                    ? Colors.red
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userController.isLoggedIn
                                        ? Icons.logout
                                        : Icons.contact_mail_outlined,
                                    color: rwhite,
                                  ),
                                  Text(
                                    userController.isLoggedIn
                                        ? "Logout".tr
                                        : "Login".tr,
                                    style: TextStyle(color: rwhite),
                                  ).marginOnly(left: 8),
                                ],
                              ).paddingAll(12),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarPopup() async {
    String? avatarPath = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Your Avatar"),
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
}

Widget _avatarOption(BuildContext context, String imagePath) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context, imagePath); // Return selected image path
    },
    child: Image.asset(imagePath, width: 80, height: 80),
  );
}

class SettingTile extends StatefulWidget {
  final SettingsModel _settingsModel;
  final function;

  const SettingTile(this._settingsModel, this.function, {super.key});

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.function();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rbluedark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                widget._settingsModel.icon,
                color: rbluedark,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget._settingsModel.title.tr,
                    style: const TextStyle(
                      color: rbluedark,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget._settingsModel.subTitle.isNotEmpty)
                    Text(
                      widget._settingsModel.subTitle.tr,
                      style: TextStyle(
                        color: rblack.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
