import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-7984236421784231/8879981117';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-7984236421784231/9563078215';
      }
    }

    // Test IDs for Debug mode
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-7984236421784231/8879981117';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-7984236421784231/9563078215';
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
