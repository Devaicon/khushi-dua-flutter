import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../controllers/donationController.dart';
import '../../models/donationSettings.dart';
import '../../widgets/customLoading.dart';
import '../../widgets/topBar.dart';

/// Switches the app's donation cards, strips and reminder on and off.
///
/// Nothing changes in the app until "Save & publish"; then every running app
/// picks the change up within seconds, and others on their next launch.
class DonationsTab extends StatefulWidget {
  const DonationsTab({super.key});

  @override
  State<DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<DonationsTab> {
  bool _enabled = true;
  final Map<String, bool> _shown = {
    for (final key in DonationSettings.placements.keys) key: true,
  };

  /// Guards against re-seeding the switches every time the controller
  /// notifies.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DonationController>().load();
    });
  }

  void _seedFrom(DonationSettings settings) {
    if (_seeded) return;
    _seeded = true;
    _enabled = settings.enabled;
    for (final key in DonationSettings.placements.keys) {
      _shown[key] = settings.isOn(key);
    }
  }

  Future<void> _save() async {
    await Get.find<DonationController>().save(
      DonationSettings(enabled: _enabled, shown: Map.of(_shown)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<DonationController>(
        builder: (controller) {
          if (controller.loaded) _seedFrom(controller.settings);

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TopBar(title: "Donations"),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          _section(
                            title: "All donation prompts",
                            child: _switch(
                              title: "Show donation prompts in the app",
                              subtitle:
                                  "Off hides every card, button and reminder "
                                  "below, whatever their own switches say.",
                              value: _enabled,
                              onChanged: (v) => setState(() => _enabled = v),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _section(
                            title: "Where they appear",
                            child: Column(
                              children: [
                                for (final MapEntry(key: key, value: label)
                                    in DonationSettings.placements.entries)
                                  _switch(
                                    title: label,
                                    subtitle: _hints[key],
                                    value: _shown[key]!,
                                    // Greyed while everything is off, but
                                    // still settable for when it is back on.
                                    dimmed: !_enabled,
                                    onChanged: (v) =>
                                        setState(() => _shown[key] = v),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _saveButton(controller),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.loading) const CustomLoading(),
            ],
          );
        },
      ),
    );
  }

  static const Map<String, String> _hints = {
    'home': 'The "Support LearningSouls" card on the home screen.',
    'search': 'The card under the quick filters on the Search screen.',
    'searchPill': 'The small Donate button in the Search screen header.',
    'prayer': 'The card at the bottom of the Prayer Times screen.',
    'settings': 'The Donate row in Settings, under Support.',
    'reminder':
        'The weekly Friday notification, and its switch in Settings. Off '
        'cancels it on every phone; back on restores it for readers who '
        'had it on.',
  };

  Widget _switch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool dimmed = false,
  }) {
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: rGreen,
        value: value,
        title: Text(title, style: const TextStyle(color: rWhite)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(color: rHint, fontSize: 12)),
        onChanged: onChanged,
      ),
    );
  }

  Widget _saveButton(DonationController controller) {
    return InkWell(
      onTap: controller.loading ? null : _save,
      child: Container(
        width: 220,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: rGreen),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [rGreen.withOpacity(0.22), rGreen.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Save & publish",
          style: TextStyle(
            color: rWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: rWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
