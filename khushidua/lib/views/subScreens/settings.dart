import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../controllers/reminderController.dart';
import '../../controllers/userController.dart';
import '../auth/signupScreen.dart';
import '../../services/authService.dart';
import '../subSettings/languageSettings.dart';
import '../subSettings/audioDownloadSettings.dart';
import '../subSettings/azkarReminderSettings.dart';
import '../subSettings/salahReminderSettings.dart';
import '../../widgets/profileAvatar.dart';
import '../../widgets/customSnackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void downloadSettings() {
    Get.to(const AudioDownloadSettings(), transition: Transition.fade);
  }

  void languageSettings() {
    Get.to(const LanguageSettings(), transition: Transition.fade);
  }

  void azkarReminderSettings() {
    Get.to(const AzkarReminderSettings(), transition: Transition.fade);
  }

  void salahReminderSettings() {
    Get.to(const SalahReminderSettings(), transition: Transition.fade);
  }

  void shareApp() async {
    try {
      debugPrint("📤 Settings: Share App button pressed");

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

      debugPrint("📤 Attempting to share app...");

      // Get screen position for iPad compatibility
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(0, 0, 100, 100); // Fallback position

      debugPrint("📍 Share position: $sharePositionOrigin");

      final result = await Share.share(
        shareMessage,
        subject: 'Khushi Dua - Islamic Learning App',
        sharePositionOrigin: sharePositionOrigin, // Required for iPad
      );

      debugPrint('✅ Share result: ${result.status}');

      if (result.status == ShareResultStatus.success) {
        CustomSnackbar.show(
          'Success',
          'Thank you for sharing!',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Share error: $e');
      CustomSnackbar.show(
        'Error',
        'Failed to share app. Please try again.',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: GetBuilder<UserController>(
        builder: (userController) {
          return GetBuilder<ReminderController>(
            builder: (reminders) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpace.xxl),
                children: [
                  _buildProfileHeader(userController),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SettingsGroup(
                          title: "PREFERENCES".tr,
                          rows: [
                            _SettingsRow(
                              icon: Icons.download_rounded,
                              seed: const Color(0xFF26A69A),
                              title: "Downloads".tr,
                              subtitle: "Audio Downloads".tr,
                              onTap: downloadSettings,
                            ),
                            _SettingsRow(
                              icon: Icons.translate_rounded,
                              seed: const Color(0xFF5C6BC0),
                              title: "Language".tr,
                              subtitle: "Change app language".tr,
                              trailingText: userController.selectedLanguage,
                              onTap: languageSettings,
                            ),
                          ],
                        ),
                        _SettingsGroup(
                          title: "REMINDERS".tr,
                          rows: [
                            _SettingsRow(
                              icon: Icons.wb_twilight_rounded,
                              seed: const Color(0xFFFFA726),
                              title: "Azkar Reminders".tr,
                              subtitle: "Morning and evening Azkar".tr,
                              status: reminders.azkarEnabled,
                              onTap: azkarReminderSettings,
                            ),
                            _SettingsRow(
                              icon: Icons.mosque_rounded,
                              seed: const Color(0xFF42A5F5),
                              title: "Salah Reminders".tr,
                              subtitle: "Get notified at prayer times".tr,
                              status: reminders.salahEnabled,
                              onTap: salahReminderSettings,
                            ),
                          ],
                        ),
                        _SettingsGroup(
                          title: "SUPPORT".tr,
                          rows: [
                            _SettingsRow(
                              icon: Icons.ios_share_rounded,
                              seed: const Color(0xFFEC407A),
                              title: "Share".tr,
                              subtitle: "Share with friends".tr,
                              onTap: shareApp,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xl),
                        _buildAccountButton(userController),
                        const SizedBox(height: AppSpace.xl),
                        Center(
                          child: Text(
                            "Version 2.0.0".tr,
                            style: TextStyle(
                              color: AppText.onPageMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// A compact identity card: avatar, name and the two stats, instead of the
  /// old 320px banner that pushed every setting below the fold.
  Widget _buildProfileHeader(UserController userController) {
    final name = userController.isLoggedIn
        ? userController.userName
        : "Guest User".tr;
    final email = userController.userModel?.email ?? "";

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: cardDecoration(rbluedark, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeInAnimationTTB(
                delay: 1,
                child: GestureDetector(
                  onTap: _showAvatarPopup,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const ProfileAvatar(size: 72, showBorder: false),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppElevation.card,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: rbluedark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: FadeInAnimationBTT(
                  delay: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppText.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppText.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Row(
            children: [
              Expanded(
                child: _statPill(
                  Icons.emoji_events_rounded,
                  userController.points.toString(),
                  "Points".tr,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _statPill(
                  Icons.menu_book_rounded,
                  (userController.userModel?.readDuas.length ?? 0).toString(),
                  "Duas Read".tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm + 4),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppText.onSurface, size: 20),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppText.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppText.onSurfaceMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton(UserController userController) {
    final loggedIn = userController.isLoggedIn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.cardAll,
        onTap: () async {
          if (loggedIn) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            await AuthService().signOut();
            userController.setLoggedIn(false);
            Get.find<UserController>().setUserName("Guest User");
            Get.find<UserController>().setPoints(0);
            CustomSnackbar.show("Success", "Logged out successfully".tr);
          } else {
            Get.to(() => const SignupScreen(), transition: Transition.downToUp);
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
          decoration: cardDecoration(
            loggedIn ? const Color(0xFFE53935) : const Color(0xFF2E9E5B),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                loggedIn ? Icons.logout_rounded : Icons.login_rounded,
                color: AppText.onSurface,
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                loggedIn ? "Logout Account".tr : "Sign In / Sign Up".tr,
                style: const TextStyle(
                  color: AppText.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
          title: Center(
            child: Text(
              "Select Your Avatar".tr,
              style: const TextStyle(
                color: rbluedark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _avatarOption(context, "assets/images/male.png"),
                _avatarOption(context, "assets/images/female.png"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel".tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );

    if (avatarPath != null) {
      Get.find<UserController>().setAvatar(avatarPath);
    }
  }

  Widget _avatarOption(BuildContext context, String imagePath) {
    return InkWell(
      onTap: () => Navigator.pop(context, imagePath),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: plainCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 90, height: 90),
            const SizedBox(height: 8),
            Text(
              isGirlAvatar(imagePath) ? "Girl".tr : "Boy".tr,
              style: const TextStyle(
                color: rbluedark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One titled section: a single rounded surface with divided rows, the way
/// native settings screens group related options.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xs,
            AppSpace.xl,
            AppSpace.xs,
            AppSpace.sm,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppText.onPageMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: plainCardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  // Indented to start under the text, past the icon tile.
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 68,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.seed,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.status,
  });

  final IconData icon;
  final Color seed;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// A current value shown before the chevron, such as the language.
  final String? trailingText;

  /// When set, a dot showing whether the feature is switched on.
  final bool? status;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppGradient.forSeed(seed),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: AppText.onSurface, size: 20),
            ),
            const SizedBox(width: AppSpace.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppText.onPage,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppText.onPageMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.sm),
                child: Text(
                  trailingText!,
                  style: TextStyle(color: AppText.onPageMuted, fontSize: 13),
                ),
              ),
            if (status != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: AppSpace.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status!
                      ? const Color(0xFF2E9E5B)
                      : Colors.grey.shade400,
                ),
              ),
            const SizedBox(width: AppSpace.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
