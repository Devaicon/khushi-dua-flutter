import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // Replace these with your actual production Ad Unit IDs from AdMob Console
  // These are currently set to Google's Test IDs
  // In lib/helpers/adHelper.dart
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) return 'YOUR_PROD_ANDROID_BANNER_ID';
      if (Platform.isIOS) return 'YOUR_PROD_IOS_BANNER_ID';
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitialAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        // TODO: Replace with your production Android Interstitial Ad Unit ID
        return 'ca-app-pub-3940256099942544/1033173712';
      } else if (Platform.isIOS) {
        // TODO: Replace with your production iOS Interstitial Ad Unit ID
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }

    // Test IDs
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
