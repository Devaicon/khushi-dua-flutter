import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../helpers/sectionProgress.dart';

/// Explains what "listened" means and how locked sections open, for readers
/// who have never seen the rule.
///
/// The rule itself lives in `AudioController` (a dua is listened once its
/// audio plays to the end while logged in) and `helpers/sectionProgress.dart`.

const String kSectionUnlockTipSeenKey = 'tipSeen.sectionUnlock';
const String kListenedTipSeenKey = 'tipSeen.listened';

String sectionUnlockSummary(SectionProgress progress) =>
    "Listen to every dua in the first @count sections to unlock the rest."
        .trParams({'count': '${progress.freeSectionCount}'});

/// Bottom sheet shown from the info button or when a locked section is tapped.
void showSectionUnlockHelp(SectionProgress progress) {
  Get.bottomSheet(
    SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: rwhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_open_rounded, color: rbluedark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "How to unlock sections".tr,
                    style: const TextStyle(
                      color: rbluedark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HelpLine(
              icon: Icons.headphones_rounded,
              text:
                  "A dua counts as listened when you play its audio all the way to the end."
                      .tr,
            ),
            _HelpLine(
              icon: Icons.stop_circle_outlined,
              text: "Stopping the audio early does not count.".tr,
            ),
            _HelpLine(
              icon: Icons.check_circle_rounded,
              text: "Listened duas show a Listened mark.".tr,
            ),
            _HelpLine(
              icon: Icons.lock_rounded,
              text: sectionUnlockSummary(progress),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.freeSectionCount == 0
                    ? 1
                    : progress.completedFreeSections /
                          progress.freeSectionCount,
                minHeight: 8,
                backgroundColor: rhint.withOpacity(0.2),
                color: rbluedark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "@done of @total sections complete".trParams({
                'done': '${progress.completedFreeSections}',
                'total': '${progress.freeSectionCount}',
              }),
              style: const TextStyle(color: rtext, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Got it".tr,
                  style: const TextStyle(color: rbluedark),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: rtext.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: rtext, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dismissible tip card shown until the reader taps "Got it" once.
class FirstTimeTip extends StatefulWidget {
  const FirstTimeTip({
    super.key,
    required this.prefsKey,
    required this.message,
    required this.color,
  });

  /// SharedPreferences flag recording that the tip was dismissed.
  final String prefsKey;
  final String message;
  final Color color;

  @override
  State<FirstTimeTip> createState() => _FirstTimeTipState();
}

class _FirstTimeTipState extends State<FirstTimeTip> {
  // Hidden until preferences load, so a dismissed tip never flashes up.
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.prefsKey) ?? false;
    if (mounted && !seen) setState(() => _visible = true);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: rbluedark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: rtext,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _dismiss,
            child: Text(
              "Got it".tr,
              style: const TextStyle(
                color: rbluedark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "Listened" chip for a dua whose audio has been played to the end.
class ListenedBadge extends StatelessWidget {
  const ListenedBadge({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      message:
          "You played this dua's audio all the way to the end.".tr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 16, color: rbluedark),
            const SizedBox(width: 4),
            Text(
              "Listened".tr,
              style: const TextStyle(
                color: rbluedark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
