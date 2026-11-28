import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

import '../../controllers/appearanceController.dart';
import '../../controllers/donationController.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/colors.dart';
import '../../constants/firebaseRef.dart';
import '../../constants/theme.dart';
import '../../controllers/localization.dart';
import '../../controllers/reminderController.dart';
import '../../controllers/prayerSettingsController.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../models/storeLinks.dart';
import '../../services/settingsBackup.dart';
import '../legalScreen.dart';
import 'notifications.dart';
import '../subSettings/audioDownloadSettings.dart';
import '../subSettings/azkarReminderSettings.dart';
import '../subSettings/prayerTimeSettings.dart';
import '../subSettings/salahReminderSettings.dart';
import '../../widgets/profileAvatar.dart';
import '../../widgets/profileEditor.dart';
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

  /// Writes the portable settings to a JSON file and opens the share sheet,
  /// so the reader can save it to Files or Drive, or send it to themselves.
  Future<void> exportSettings() async {
    try {
      final json = await SettingsBackup.export();
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File('${dir.path}/khushi-dua-settings-$stamp.json');
      await file.writeAsString(json);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Khushi Dua settings',
        // Required on iPad, where the sheet is a popover.
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      debugPrint('Settings export failed: $e');
      CustomSnackbar.show(
        "Error".tr,
        "Could not export your settings. Please try again.".tr,
        isSuccess: false,
      );
    }
  }

  /// Reads a backup file, confirms, then replaces the settings with it and
  /// applies them straight away: no restart needed.
  Future<void> importSettings() async {
    final Map<String, Object> values;
    try {
      // Any file type: Android often reports JSON as a generic file, so a
      // filter on .json would hide the very file the reader saved.
      final picked = await FilePicker.pickFile();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      values = SettingsBackup.decode(utf8.decode(bytes, allowMalformed: true));
    } on BackupFormatException catch (e) {
      CustomSnackbar.show(
        "Error".tr,
        e.newerVersion
            ? "This backup is from a newer version of the app. Please update the app first."
                  .tr
            : "This file is not a Khushi Dua settings backup.".tr,
        isSuccess: false,
      );
      return;
    } catch (e) {
      debugPrint('Settings import failed: $e');
      CustomSnackbar.show(
        "Error".tr,
        "Could not read that file.".tr,
        isSuccess: false,
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text("Replace your settings?".tr),
        content: Text(
          "Your settings and listening progress on this phone will be replaced with the ones in the backup."
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text("Import".tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SettingsBackup.apply(values);
    await Get.find<UserController>().load();
    await Get.find<AppearanceController>().reload();
    await Get.find<ThemeController>().reload();
    await Get.find<PrayerSettingsController>().reload();
    final notificationsAllowed = await Get.find<ReminderController>().reload();

    CustomSnackbar.show(
      "Success".tr,
      notificationsAllowed
          ? "Your settings have been imported.".tr
          : "Settings imported. Allow notifications to get your reminders."
                .tr,
      isSuccess: notificationsAllowed,
    );
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

      // Links come from the admin panel's App Controls tab. The offline
      // cache answers instantly; a phone that has never seen the document
      // (or is slow to reach Firestore) shares the built-in links.
      StoreLinks links = const StoreLinks();
      try {
        final snap = await sysConfigRef
            .doc(StoreLinks.docId)
            .get()
            .timeout(const Duration(seconds: 3));
        links = StoreLinks.fromMap(snap.data());
      } catch (e) {
        debugPrint("📤 Store links unavailable, using defaults: $e");
      }
      final appUrl = Platform.isIOS ? links.appStore : links.playStore;
      final shareMessage =
          'Check out Khushi Dua - Islamic Learning App\n\n'
          '📿 Read beautiful Islamic Duas\n'
          '🕋 Find Qibla direction\n'
          '⏰ Prayer times\n\n'
          'Download now:\n'
          '$appUrl';

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
            builder: (reminders) => GetBuilder<DonationController>(
              builder: (donations) => ListView(
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
                            _SettingsRow(
                              icon: Icons.dark_mode_rounded,
                              seed: const Color(0xFF455A64),
                              title: "Appearance".tr,
                              subtitle: "Light, dark or match your phone".tr,
                              trailing: GetBuilder<AppearanceController>(
                                builder: (appearance) =>
                                    _buildAppearanceDropdown(appearance),
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
                            // Hidden while the admin has switched it off.
                            if (reminders.supportAllowed)
                              _SettingsRow(
                                icon: Icons.favorite_rounded,
                                seed: kDonateSeed,
                                title: "Support reminder".tr,
                                subtitle: "A weekly reminder to donate".tr,
                                trailing: Switch(
                                  value: reminders.supportEnabled,
                                  onChanged: (value) async {
                                    final ok = await reminders
                                        .setSupportEnabled(value);
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
                            if (donations.settings.settings)
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
                        // Moving to another phone, now that there are no
                        // accounts to sign in to.
                        _SettingsGroup(
                          title: "BACKUP".tr,
                          rows: [
                            _SettingsRow(
                              icon: Icons.upload_file_rounded,
                              seed: const Color(0xFF00897B),
                              title: "Export settings".tr,
                              subtitle:
                                  "Save your settings and progress to a file"
                                      .tr,
                              onTap: exportSettings,
                            ),
                            _SettingsRow(
                              icon: Icons.download_for_offline_rounded,
                              seed: const Color(0xFF5E35B1),
                              title: "Import settings".tr,
                              subtitle: "Restore from a backup file".tr,
                              onTap: importSettings,
                            ),
                          ],
                        ),
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
              ),
            ),
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
        dropdownColor: AppSurface.card,
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
                    style: TextStyle(color: AppText.onPage, fontSize: 15),
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

  /// Light, dark or the phone's setting, in the language picker's style.
  Widget _buildAppearanceDropdown(AppearanceController appearance) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: appearance.mode,
        isDense: true,
        icon: Icon(
          Icons.expand_more_rounded,
          color: Colors.grey.shade400,
          size: 22,
        ),
        dropdownColor: AppSurface.card,
        borderRadius: AppRadius.cardAll,
        style: TextStyle(color: AppText.onPageMuted, fontSize: 13),
        selectedItemBuilder: (context) => [
          for (final label in AppearanceController.modes.values)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(label.tr),
            ),
        ],
        items: [
          for (final MapEntry(key: mode, value: label)
              in AppearanceController.modes.entries)
            DropdownMenuItem<String>(
              value: mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.tr,
                    style: TextStyle(color: AppText.onPage, fontSize: 15),
                  ),
                  if (mode == appearance.mode) ...[
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
          if (value != null) appearance.setMode(value);
        },
      ),
    );
  }

  /// A compact identity card: avatar, name and the two stats. Tapping it
  /// edits the optional name and avatar; nothing asks the reader to sign up.
  Widget _buildProfileHeader(UserController userController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showProfileEditor,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: cardDecoration(kBrandNavy, radius: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const ProfileAvatar(size: 72, showBorder: false),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppSurface.card,
                              shape: BoxShape.circle,
                              boxShadow: AppElevation.card,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: rbluedark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userController.hasName
                                ? userController.userName
                                : "Add your name".tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppText.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Saved on this phone. No account needed.".tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppText.onSurfaceMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                        userController.listenedCount.toString(),
                        "Duas Read".tr,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                    style: TextStyle(
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
