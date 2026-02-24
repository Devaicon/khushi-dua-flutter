import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void show(String title, String message, {bool isSuccess = true}) {
    // Use WidgetsBinding to ensure the overlay is ready before showing snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          colorText: Colors.white,
          borderRadius: 10,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          icon: Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          shouldIconPulse: true,
          duration: Duration(seconds: 3),
          forwardAnimationCurve: Curves.easeOutBack,
          reverseAnimationCurve: Curves.easeInBack,
          overlayBlur: 1, // Adds a blur effect to background
          isDismissible: true,
          // mainButton: TextButton(
          //   onPressed: () => Get.back(),
          //   child: Text(
          //     "OK",
          //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          //   ),
          // ),
        );
      }
    });
  }
}
