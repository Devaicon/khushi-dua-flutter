import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../helpers/reminderSchedule.dart';
import 'reminderService.dart';

/// Plays a Salah alert the moment it is chosen, so the user hears or feels
/// what they are picking.
///
/// On Android the sound and vibration are played directly: a preview posted
/// as a notification was muted by Android's notification cooldown whenever
/// two options were tried in a row. iOS has no such API, so it still posts a
/// real notification, which iOS shows even with the app open.
abstract final class AlertPreview {
  static const MethodChannel _channel = MethodChannel(
    'com.khushiidua.app/alertPreview',
  );

  /// Returns false when nothing could be played.
  static Future<bool> play(
    SalahChannel channel, {
    required String title,
    required String body,
  }) async {
    if (channel == SalahChannel.none) {
      await stop();
      return true;
    }
    if (!Platform.isAndroid) {
      if (!await ReminderService.instance.requestPermissions()) return false;
      await ReminderService.instance.previewSalah(
        channel,
        title: title,
        body: body,
      );
      return true;
    }
    try {
      final played = await _channel.invokeMethod<bool>(
        channel == SalahChannel.vibrate ? 'vibrate' : 'playSound',
        switch (channel) {
          SalahChannel.haya => {'raw': ReminderService.salahSoundAndroid},
          SalahChannel.vibrate => {
            'pattern': ReminderService.salahVibrationPattern.toList(),
          },
          _ => <String, Object?>{'raw': null},
        },
      );
      return played ?? false;
    } catch (e) {
      debugPrint('🔔 AlertPreview: $e');
      return false;
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e) {
      debugPrint('🔔 AlertPreview: stop failed: $e');
    }
  }
}
