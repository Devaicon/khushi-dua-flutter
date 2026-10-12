import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';

/// A brief note in the bottom corner after something is saved or fails.
///
/// It used to drop from the top in bright green or red with a blur over the
/// whole screen; this one stays out of the way and leaves the screen usable.
class CustomSnackbar {
  static void show(String title, String message, {bool isSuccess = true}) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    final color = isSuccess ? Palette.success : Palette.danger;
    Get.rawSnackbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: Palette.text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(color: Palette.textMuted, fontSize: 13),
      ),
      icon: Icon(
        isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
        color: color,
      ),
      backgroundColor: Palette.card,
      borderRadius: Radii.sm,
      borderColor: color.withValues(alpha: 0.35),
      borderWidth: 1,
      boxShadows: Elevation.card,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 420,
      margin: const EdgeInsets.all(Space.xl),
      padding: const EdgeInsets.all(Space.lg),
      duration: Duration(seconds: isSuccess ? 3 : 6),
      animationDuration: Motion.base,
      isDismissible: true,
    );
  }
}
