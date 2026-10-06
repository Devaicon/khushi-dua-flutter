import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../constants/prayerNames.dart';
import '../controllers/reminderController.dart';

/// In-app banner shown while a prayer time is current.
///
/// Complements the system notification: the notification reaches a user who is
/// elsewhere, this reaches one who already has the app open. Renders nothing
/// when the reminders are off, outside the window, or once dismissed.
class SalahBanner extends StatefulWidget {
  const SalahBanner({super.key, this.topGap = 0, this.bottomGap = 0});

  /// Space above and below the banner, applied only while it is showing, so a
  /// hidden banner leaves no hole in the layout around it.
  final double topGap;
  final double bottomGap;

  @override
  State<SalahBanner> createState() => _SalahBannerState();
}

class _SalahBannerState extends State<SalahBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The window opens and closes on wall-clock time, so re-evaluate
    // periodically rather than only when something else rebuilds.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReminderController>(
      builder: (reminder) {
        final active = reminder.activeSalahBanner();
        if (active == null) return const SizedBox.shrink();

        final arabic = arabicPrayerName(active.name);

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: widget.topGap, bottom: widget.bottomGap),
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            gradient: AppGradient.forSeed(kBrandNavy),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${"It is time for".tr} ${active.name.tr}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (arabic.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            arabic,
                            style: TextStyle(
                              fontFamily: 'arabic',
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('hh:mm a').format(active.time),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
                onPressed: () =>
                    reminder.dismissSalahBanner(active.name, active.time),
                tooltip: "Dismiss".tr,
              ),
            ],
          ),
        );
      },
    );
  }
}
