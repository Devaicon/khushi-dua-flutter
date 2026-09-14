import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../controllers/reminderController.dart';
import '../../widgets/customSnackbar.dart';

/// Master switch for the Azkar reminders, plus the morning and evening times.
///
/// The time pickers only appear once the reminders are on, so the screen never
/// offers a setting that would have no effect.
class AzkarReminderSettings extends StatelessWidget {
  const AzkarReminderSettings({super.key});

  Future<void> _pickTime(
    BuildContext context,
    ReminderController controller, {
    required bool isMorning,
  }) async {
    final current = isMorning ? controller.morningTime : controller.eveningTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: (isMorning ? "Morning reminder" : "Evening reminder").tr,
    );
    if (picked == null) return;

    if (isMorning) {
      await controller.setMorningTime(picked);
    } else {
      await controller.setEveningTime(picked);
    }
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
            "Azkar Reminders".tr,
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
                    value: controller.azkarEnabled,
                    title: Text(
                      "Daily Azkar reminders".tr,
                      style: const TextStyle(
                        color: rbluedark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Get reminded for morning and evening Azkar".tr,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) async {
                      final ok = await controller.setAzkarEnabled(value);
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
                if (controller.azkarEnabled) ...[
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      children: [
                        _timeRow(
                          context,
                          controller,
                          icon: Icons.wb_sunny_rounded,
                          label: "Morning Azkar".tr,
                          time: controller.morningTime,
                          isMorning: true,
                        ),
                        Divider(color: Colors.grey.withOpacity(0.15)),
                        _timeRow(
                          context,
                          controller,
                          icon: Icons.nightlight_round,
                          label: "Evening Azkar".tr,
                          time: controller.eveningTime,
                          isMorning: false,
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

  Widget _timeRow(
    BuildContext context,
    ReminderController controller, {
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required bool isMorning,
  }) {
    return InkWell(
      onTap: () => _pickTime(context, controller, isMorning: isMorning),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rbluedark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: rbluedark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: rbluedark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              time.format(context),
              style: const TextStyle(
                color: rbluedark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
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
