import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../controllers/localization.dart';
import '../../controllers/reminderController.dart';
import '../../controllers/userController.dart';
import '../auth/signupScreen.dart';
import '../legalScreen.dart';
import 'notifications.dart';
import '../../services/authService.dart';
import '../subSettings/audioDownloadSettings.dart';
import '../subSettings/azkarReminderSettings.dart';
import '../subSettings/prayerTimeSettings.dart';
import '../subSettings/salahReminderSettings.dart';
import '../../widgets/profileAvatar.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/donateCard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void downloadSettings() {
    Get.to(const AudioDownloadSettings(), transition: Transition.fade);
  }

  static const List<Map<String, String>> _languages = [
    {"name": "Arabic", "flag": "🇸🇦"},
    {"name": "Bengali", "flag": "🇧🇩"},
    {"name": "English", "flag": "🇺🇸"},
    {"name": "French", "flag": "🇫🇷"},
    {"name": "German", "flag": "🇩🇪"},
    {"name": "Gujarati", "flag": "🇮🇳"},
    {"name": "Hindi", "flag": "🇮🇳"},
    {"name": "Indonesian", "flag": "🇮🇩"},
    {"name": "Japanese", "flag": "🇯🇵"},
    {"name": "Malay", "flag": "🇲🇾"},
    {"name": "Mandarin", "flag": "🇨🇳"},
    {"name": "Marathi", "flag": "🇮🇳"},
    {"name": "Portuguese", "flag": "🇵🇹"},
    {"name": "Punjabi", "flag": "🇮🇳"},
    {"name": "Russian", "flag": "🇷🇺"},
    {"name": "Spanish", "flag": "🇪🇸"},
    {"name": "Tamil", "flag": "🇮🇳"},
    {"name": "Telugu", "flag": "🇮🇳"},
    {"name": "Turkish", "flag": "🇹🇷"},
    {"name": "Urdu", "flag": "🇵🇰"},
  ];

  Future<void> changeLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedLanguage", language);
    Localization.changeLocale(language);
    Get.find<UserController>().setSelectedLanguage(language);
  }

  static const String _feedbackEmail = 'admin@learningsouls.org';

  /// Opens a new draft in the phone's mail app, addressed and with the
  /// subject filled in.
  Future<void> sendFeedback() async {
    // The query is built by hand: Uri's queryParameters encodes spaces as
    // "+", which several mail apps show literally in the subject.
    final uri = Uri(
      scheme: 'mailto',
      path: _feedbackEmail,
      query: 'subject=${Uri.encodeComponent('Khushi Dua Feedback')}',
    );
    bool opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (e) {
      debugPrint('Feedback: could not open mail app: $e');
    }
    if (!opened) {
      CustomSnackbar.show(
        "No email app found".tr,
        "${"Write to us at".tr} $_feedbackEmail",
        isSuccess: false,
      );
    }
  }

  void openTermsAndPrivacy() {
    Get.to(() => const LegalScreen());
  }

  /// Asks once more, then deletes the account; the auth service handles the
  /// identity check and the deletion itself.
  Future<void> confirmDeleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Delete your account?".tr),
        content: Text(
          "This permanently deletes your account, points and listening progress. It cannot be undone."
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: Text("Delete".tr),
          ),
        ],
      ),
    );
    if (confirmed == true) await AuthService().deleteAccount();
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
                              icon: Icons.notifications_rounded,
                              seed: const Color(0xFF7E57C2),
                              title: "Notifications".tr,
                              subtitle: "View or delete notifications".tr,
                              onTap: () => Get.to(
                                () => const NotificationScreen(),
                                transition: Transition.fade,
                              ),
                            ),
                            _SettingsRow(
                              icon: Icons.schedule_rounded,
                              seed: const Color(0xFF3949AB),
                              title: "Prayer Times".tr,
                              subtitle: "Calculation and juristic method".tr,
                              onTap: () => Get.to(
                                () => const PrayerTimeSettings(),
                                transition: Transition.fade,
                              ),
                            ),
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
                              trailing: _buildLanguageDropdown(
                                userController.selectedLanguage,
                              ),
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
                            _SettingsRow(
                              icon: Icons.favorite_rounded,
                              seed: kDonateSeed,
                              title: "Support reminder".tr,
                              subtitle: "A weekly reminder to donate".tr,
                              trailing: Switch(
                                value: reminders.supportEnabled,
                                onChanged: (value) async {
                                  final ok = await reminders.setSupportEnabled(
                                    value,
                                  );
                                  if (!ok) {
                                    CustomSnackbar.show(
                                      "Error".tr,
                                      "Notification permission is required for reminders"
                                          .tr,
                                      isSuccess: false,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        _SettingsGroup(
                          title: "SUPPORT".tr,
                          rows: [
                            _SettingsRow(
                              icon: Icons.volunteer_activism_rounded,
                              seed: kDonateSeed,
                              title: "Donate".tr,
                              subtitle: "Support LearningSouls".tr,
                              onTap: openDonate,
                            ),
                            _SettingsRow(
                              icon: Icons.ios_share_rounded,
                              seed: const Color(0xFFEC407A),
                              title: "Share".tr,
                              subtitle: "Share with friends".tr,
                              onTap: shareApp,
                            ),
                            _SettingsRow(
                              icon: Icons.mail_rounded,
                              seed: const Color(0xFF26A69A),
                              title: "Feedback".tr,
                              subtitle: "Send us an email".tr,
                              onTap: sendFeedback,
                            ),
                            _SettingsRow(
                              icon: Icons.menu_book_rounded,
                              seed: const Color(0xFF8D6E63),
                              title: "References".tr,
                              subtitle: "Sources and credits".tr,
                              onTap: () =>
                                  Get.to(() => const ReferencesScreen()),
                            ),
                            _SettingsRow(
                              icon: Icons.privacy_tip_rounded,
                              seed: const Color(0xFF78909C),
                              title: "Terms & Privacy".tr,
                              subtitle: "Terms of use and privacy policy".tr,
                              onTap: openTermsAndPrivacy,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xl),
                        _buildAccountButton(userController),
                        if (userController.isLoggedIn) ...[
                          const SizedBox(height: AppSpace.sm),
                          Center(
                            child: TextButton.icon(
                              onPressed: confirmDeleteAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE53935),
                              ),
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                size: 18,
                              ),
                              label: Text("Delete account".tr),
                            ),
                          ),
                        ],
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

  /// The language picker, inline in its settings row rather than on a
  /// screen of its own.
  Widget _buildLanguageDropdown(String selected) {
    final isKnown = _languages.any((l) => l["name"] == selected);
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: isKnown ? selected : null,
        // Keeps the row the same height as its neighbours.
        isDense: true,
        icon: Icon(
          Icons.expand_more_rounded,
          color: Colors.grey.shade400,
          size: 22,
        ),
        dropdownColor: Colors.white,
        borderRadius: AppRadius.cardAll,
        menuMaxHeight: 420,
        style: TextStyle(color: AppText.onPageMuted, fontSize: 13),
        // The closed button shows just the flag and name; the menu adds a
        // check against the current choice.
        selectedItemBuilder: (context) => [
          for (final language in _languages)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text("${language['flag']} ${language['name']}"),
            ),
        ],
        items: [
          for (final language in _languages)
            DropdownMenuItem<String>(
              value: language['name'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${language['flag']} ${language['name']}",
                    style: const TextStyle(color: AppText.onPage, fontSize: 15),
                  ),
                  if (language['name'] == selected) ...[
                    const SizedBox(width: AppSpace.sm),
                    const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF2E9E5B),
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null && value != selected) changeLanguage(value);
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
    this.onTap,
    this.trailing,
    this.status,
  });

  final IconData icon;
  final Color seed;
  final String title;
  final String subtitle;

  /// Null for a row whose [trailing] control handles the interaction.
  final VoidCallback? onTap;

  /// A control shown in place of the chevron, such as a dropdown.
  final Widget? trailing;

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
            trailing ??
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
