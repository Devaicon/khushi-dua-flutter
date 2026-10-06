import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../controllers/prayerSettingsController.dart';
import '../../widgets/sunPathView.dart';

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
              const SizedBox(height: AppSpace.lg),
              _SettingCard(
                icon: Icons.wb_sunny_rounded,
                title: "Next Prayer Card".tr,
                subtitle: "What the card shows under the countdown".tr,
                child: Row(
                  children: [
                    for (final (i, style)
                        in PrayerSettingsController
                            .cardStyles
                            .keys
                            .indexed) ...[
                      if (i > 0) const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: _StyleOption(
                          style: style,
                          selected: settings.cardStyle == style,
                          onTap: () => settings.setCardStyle(style),
                        ),
                      ),
                    ],
                  ],
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
                      style: TextStyle(
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
          dropdownColor: AppSurface.card,
          borderRadius: AppRadius.cardAll,
          menuMaxHeight: 420,
          style: TextStyle(
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
                        style: TextStyle(
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

/// One look for the next-prayer card, shown as a small navy preview of it.
class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A fixed mid-morning, so the preview always shows the sun up.
    final sunrise = DateTime(2000, 1, 1, 6);
    final sunset = DateTime(2000, 1, 1, 18);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: selected
              ? rbluedark.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: selected ? rbluedark : rbluedark.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              alignment: Alignment.center,
              decoration: cardDecoration(kBrandNavy, radius: AppRadius.sm),
              child: style == 'sun'
                  ? SunPathView(
                      now: DateTime(2000, 1, 1, 10, 30),
                      sunrise: sunrise,
                      sunset: sunset,
                      showTimes: false,
                      height: 44,
                    )
                  : ClipRRect(
                      borderRadius: AppRadius.pillAll,
                      child: LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check_circle_rounded, size: 16, color: rbluedark),
                  const SizedBox(width: AppSpace.xs),
                ],
                Flexible(
                  child: Text(
                    PrayerSettingsController.cardStyles[style]!.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? rbluedark : AppText.onPageMuted,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
