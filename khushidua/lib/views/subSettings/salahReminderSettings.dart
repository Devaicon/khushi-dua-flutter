import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../constants/prayerNames.dart';
import '../../controllers/reminderController.dart';
import '../../helpers/reminderSchedule.dart';
import '../../services/alertPreview.dart';
import '../../widgets/customSnackbar.dart';

/// The one place every Salah reminder setting lives: the master switch, and
/// each prayer's alert (sound, vibrate or off) and sound. Choosing an alert or
/// sound plays it. The prayer screen's bells only show the state and open this screen.
///
/// Per-prayer state is stored under the `<prayer>Speaker` and `<prayer>Sound`
/// preferences, which the scheduler reads.
class SalahReminderSettings extends StatefulWidget {
  const SalahReminderSettings({super.key});

  @override
  State<SalahReminderSettings> createState() => _SalahReminderSettingsState();
}

class _SalahReminderSettingsState extends State<SalahReminderSettings> {
  Map<String, String> _modes = {};
  Map<String, SalahSound> _sounds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadModes();
  }

  Future<void> _loadModes() async {
    final prefs = await SharedPreferences.getInstance();
    final modes = <String, String>{};
    final sounds = <String, SalahSound>{};
    for (final prayer in kSchedulablePrayers) {
      modes[prayer] = prefs.getString(salahSpeakerKeyFor(prayer)) ?? 'on';
      sounds[prayer] = salahSoundFor(prefs.getString(salahSoundKeyFor(prayer)));
    }
    if (!mounted) return;
    setState(() {
      _modes = modes;
      _sounds = sounds;
      _loading = false;
    });
  }

  @override
  void dispose() {
    // A long sound should not keep playing after the screen is closed.
    AlertPreview.stop();
    super.dispose();
  }

  /// Choosing an option plays it, so the user knows what they picked. Tapping
  /// the selected option again replays it.
  Future<void> _setPrayerMode(String prayer, String mode) async {
    _preview(prayer, mode: mode);
    if (_modes[prayer] == mode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(salahSpeakerKeyFor(prayer), mode);
    setState(() => _modes[prayer] = mode);
    // Empty map: keep the times the controller already holds.
    await Get.find<ReminderController>().syncSalahReminders(const {});
  }

  Future<void> _setPrayerSound(String prayer, SalahSound sound) async {
    _preview(prayer, sound: sound);
    if (_sounds[prayer] == sound) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(salahSoundKeyFor(prayer), salahSoundValue(sound));
    setState(() => _sounds[prayer] = sound);
    await Get.find<ReminderController>().syncSalahReminders(const {});
  }

  Future<void> _preview(
    String prayer, {
    String? mode,
    SalahSound? sound,
  }) async {
    final channel = salahChannelFor(
      salahAlertFor(mode ?? _modes[prayer]),
      sound ?? _sounds[prayer] ?? SalahSound.haya,
    );
    final ok = await Get.find<ReminderController>().previewSalah(channel);
    if (!ok && mounted) {
      CustomSnackbar.show(
        "Error".tr,
        "Notification permission is required for reminders".tr,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppSurface.page,
        appBar: AppBar(
          title: Text(
            "Salah Reminders".tr,
            style: const TextStyle(
              color: rbluedark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: rbluedark),
        ),
        body: GetBuilder<ReminderController>(
          builder: (controller) {
            return ListView(
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [
                _card(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: controller.salahEnabled,
                    title: Text(
                      "Salah reminders".tr,
                      style: const TextStyle(
                        color: rbluedark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Get notified at the time of each prayer".tr,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) async {
                      final ok = await controller.setSalahEnabled(value);
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
                if (controller.salahEnabled && !_loading) ...[
                  const SizedBox(height: AppSpace.lg),
                  _card(
                    child: Column(
                      children: [
                        for (final prayer in kSchedulablePrayers) ...[
                          if (prayer != kSchedulablePrayers.first)
                            const Divider(height: 1),
                          _prayerRow(prayer),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _prayerRow(String prayer) {
    final mode = _modes[prayer] ?? 'on';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                prayer.tr,
                style: const TextStyle(
                  color: rbluedark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                arabicPrayerName(prayer),
                style: TextStyle(
                  fontFamily: 'arabic',
                  color: AppText.onPageMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (final option in const [
                ('on', Icons.notifications_active_rounded, "Sound"),
                ('vibrate', Icons.vibration_rounded, "Vibrate"),
                ('off', Icons.notifications_off_rounded, "Off"),
              ]) ...[
                if (option.$1 != 'on') const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _choiceChip(
                    label: option.$3.tr,
                    icon: option.$2,
                    selected: salahAlertFor(mode) == salahAlertFor(option.$1),
                    onTap: () => _setPrayerMode(prayer, option.$1),
                  ),
                ),
              ],
            ],
          ),
          // Only a sounding alert has a sound to choose.
          if (salahAlertFor(mode) == SalahAlert.sound) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: _soundChip(
                    prayer,
                    SalahSound.haya,
                    "Haya al-Salah".tr,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _soundChip(
                    prayer,
                    SalahSound.deviceDefault,
                    "Notification sound".tr,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? rbluedark : rbluedark.withValues(alpha: 0.06),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : rbluedark),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : rbluedark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same look as the alert chips: the unselected sound used to be grey text
  /// on grey, which read as disabled rather than as the other choice.
  Widget _soundChip(String prayer, SalahSound sound, String label) {
    return _choiceChip(
      label: label,
      icon: sound == SalahSound.haya
          ? Icons.mosque_rounded
          : Icons.music_note_rounded,
      selected: (_sounds[prayer] ?? SalahSound.haya) == sound,
      onTap: () => _setPrayerSound(prayer, sound),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      decoration: plainCardDecoration(),
      child: child,
    );
  }
}
