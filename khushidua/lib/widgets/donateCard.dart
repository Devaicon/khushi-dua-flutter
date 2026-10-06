import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';
import '../views/donateScreen.dart';

/// The donation colour: warm, and distinct from every category and reminder
/// card so it never reads as part of the content around it.
const Color kDonateSeed = Color(0xFFE5737F);

void openDonate() =>
    Get.to(() => const DonateScreen(), transition: Transition.downToUp);

/// The "Support LearningSouls" invitation shown on the home, search and
/// prayer screens.
///
/// [onDark] swaps the solid card for a translucent one, for screens such as
/// the prayer times that already sit on a strong colour.
class DonateCard extends StatelessWidget {
  const DonateCard({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: openDonate,
      borderRadius: AppRadius.cardAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: onDark
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: AppRadius.cardAll,
              )
            : cardDecoration(kDonateSeed),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.smAll,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppText.onSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Support LearningSouls".tr,
                    style: const TextStyle(
                      color: AppText.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Your donation keeps Khushi Dua free for every child".tr,
                    style: TextStyle(
                      color: AppText.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pillAll,
              ),
              child: Text(
                "Donate".tr,
                style: TextStyle(
                  color: onDark ? const Color(0xFF1A237E) : kDonateSeed.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
