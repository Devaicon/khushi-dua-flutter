import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../constants/prayerNames.dart';
import '../../controllers/reminderController.dart';
import '../../helpers/reminderSchedule.dart';
import '../../widgets/customSnackbar.dart';

/// Master switch for the Salah reminders, plus a per-prayer switch.
///
/// The per-prayer state is the same `<prayer>Speaker` preference the prayer
/// screen's speaker icons already write, so the two stay in sync. That icon
/// cycles on → off → vibrate; this screen only distinguishes off from not-off,
/// and writes "on" when re-enabling.
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

  Future<void> _setPrayerEnabled(String prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = enabled ? 'on' : 'off';
    await prefs.setString(salahSpeakerKeyFor(prayer), mode);
    setState(() => _modes[prayer] = mode);
    // Empty map: keep the times the controller already holds.
    await Get.find<ReminderController>().syncSalahReminders(const {});
  }

  Future<void> _setPrayerSound(String prayer, SalahSound sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(salahSoundKeyFor(prayer), salahSoundValue(sound));
    setState(() => _sounds[prayer] = sound);
    await Get.find<ReminderController>().syncSalahReminders(const {});
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
                        for (final prayer in kSchedulablePrayers)
                          _prayerRow(prayer),
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
    final enabled = _modes[prayer] != 'off';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          title: Row(
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
          onChanged: (v) => _setPrayerEnabled(prayer, v),
        ),
        // The sound choice only means something while the prayer alerts, and
        // vibrate-only has no sound to choose.
        if (enabled && _modes[prayer] != 'vibrate')
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpace.md,
              right: AppSpace.sm,
            ),
            child: Row(
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
          ),
      ],
    );
  }

  Widget _soundChip(String prayer, SalahSound sound, String label) {
    final selected = (_sounds[prayer] ?? SalahSound.haya) == sound;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected ? null : () => _setPrayerSound(prayer, sound),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? AppGradient.forSeed(rbluedark)
              : AppGradient.neutral,
          borderRadius: AppRadius.pillAll,
          boxShadow: selected ? AppElevation.card : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppText.onSurface : AppText.onPageMuted,
            ),
          ),
        ),
      ),
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
