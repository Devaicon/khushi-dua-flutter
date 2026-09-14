import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadModes();
  }

  Future<void> _loadModes() async {
    final prefs = await SharedPreferences.getInstance();
    final modes = <String, String>{};
    for (final prayer in kSchedulablePrayers) {
      modes[prayer] = prefs.getString(_speakerKeyFor(prayer)) ?? 'on';
    }
    if (!mounted) return;
    setState(() {
      _modes = modes;
      _loading = false;
    });
  }

  /// Mirrors the key naming used by the prayer screen.
  String _speakerKeyFor(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return 'fajrSpeaker';
      case 'Dhuhr':
        return 'dhuhrSpeaker';
      case 'Asr':
        return 'asrSpeaker';
      case 'Maghrib':
        return 'maghribSpeaker';
      case 'Ishaa':
        return 'ishaSpeaker';
      default:
        return '${prayer.toLowerCase()}Speaker';
    }
  }

  Future<void> _setPrayerEnabled(String prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = enabled ? 'on' : 'off';
    await prefs.setString(_speakerKeyFor(prayer), mode);
    setState(() => _modes[prayer] = mode);
    // Empty map: keep the times the controller already holds.
    await Get.find<ReminderController>().syncSalahReminders(const {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FE),
        appBar: AppBar(
          backgroundColor: const Color(0xffF8F9FE),
          elevation: 0,
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
              padding: const EdgeInsets.all(20),
              children: [
                _card(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: rbluedark,
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
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      children: [
                        for (final prayer in kSchedulablePrayers)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: rbluedark,
                            value: _modes[prayer] != 'off',
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
                                const SizedBox(width: 8),
                                Text(
                                  arabicPrayerName(prayer),
                                  style: TextStyle(
                                    fontFamily: 'arabic',
                                    color: rbluedark.withOpacity(0.55),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (v) => _setPrayerEnabled(prayer, v),
                          ),
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: child,
    );
  }
}
