import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void show(String title, String message, {bool isSuccess = true}) {
    final String translatedTitle = title.tr;
    final String translatedMessage = message.tr;

    debugPrint(
      "🔔 CUSTOM_SNACKBAR: Attempting show via ScaffoldMessenger - title='$translatedTitle', message='$translatedMessage'",
    );

    final context = Get.context;
    if (context == null) {
      debugPrint("❌ CUSTOM_SNACKBAR: Get.context is null!");
      // Extreme fallback to Get.snackbar if everything else fails
      Get.rawSnackbar(
        title: translatedTitle,
        message: translatedMessage,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      );
      return;
    }

    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translatedTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      translatedMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: isSuccess
              ? Colors.green.withOpacity(0.9)
              : Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint("❌ CUSTOM_SNACKBAR ERROR: $e");
      // Fallback
      Get.rawSnackbar(
        title: translatedTitle,
        message: translatedMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      );
    }
  }
}
