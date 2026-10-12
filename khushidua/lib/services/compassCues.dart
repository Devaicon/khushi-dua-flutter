import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The one vibration the Qibla compass gives: a short buzz when the phone
/// comes onto the Qibla, so it can be turned without watching the screen.
///
/// On Android it is played natively as a notification-type vibration:
/// Flutter's [HapticFeedback] goes through touch feedback, which many people
/// turn off. iOS keeps [HapticFeedback], which its Taptic Engine plays
/// regardless.
class CompassCues {
  const CompassCues._();

  static const MethodChannel _channel = MethodChannel(
    'com.khushiidua.app/compass',
  );

  static Future<void> aligned() async {
    if (!Platform.isAndroid) {
      await HapticFeedback.mediumImpact();
      return;
    }
    try {
      await _channel.invokeMethod<bool>('haptic', 'aligned');
    } on PlatformException catch (e) {
      debugPrint('🧭 CompassCues: aligned failed - ${e.message}');
    } on MissingPluginException {
      debugPrint('🧭 CompassCues: compass channel not registered');
    }
  }
}
