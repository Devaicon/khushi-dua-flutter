import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../controllers/prayerSettingsController.dart';

/// The calculation method and juristic method for prayer times, as
/// dropdowns in the style of the language picker. Opens from the prayer
/// screen and from Settings.
class PrayerTimeSettings extends StatelessWidget {
  const PrayerTimeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      appBar: AppBar(title: Text("Prayer Times".tr)),
      body: GetBuilder<PrayerSettingsController>(
        builder: (settings) {
          return ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              _SettingCard(
                icon: Icons.calculate_rounded,
                title: "Calculation Method".tr,
                subtitle: "The authority whose angles set Fajr and Isha".tr,
                child: _Dropdown(
                  selected: settings.method,
                  options: PrayerSettingsController.methods,
                  onChanged: settings.setMethod,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              _SettingCard(
                icon: Icons.menu_book_rounded,
                title: "Juristic Method".tr,
                subtitle: "Decides when Asr begins".tr,
                child: _Dropdown(
                  selected: settings.madhab,
                  options: PrayerSettingsController.madhabs,
                  onChanged: settings.setMadhab,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: plainCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  gradient: AppGradient.forSeed(const Color(0xFF5C6BC0)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: rbluedark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppText.onPageMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Full width rather than trailing like the language picker's, because the
/// method names are long; the menu marks the current choice the same way.
class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: rbluedark.withValues(alpha: 0.05),
        borderRadius: AppRadius.smAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.containsKey(selected) ? selected : null,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          dropdownColor: Colors.white,
          borderRadius: AppRadius.cardAll,
          menuMaxHeight: 420,
          style: const TextStyle(
            color: AppText.onPage,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => [
            for (final label in options.values)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final MapEntry(key: value, value: label) in options.entries)
              DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.tr,
                        style: const TextStyle(
                          color: AppText.onPage,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    if (value == selected) ...[
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
            if (value != null && value != selected) onChanged(value);
          },
        ),
      ),
    );
  }
}
