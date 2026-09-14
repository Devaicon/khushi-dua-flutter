import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../helpers/compassQuality.dart';
import '../helpers/worldMagneticModel.dart';

/// Everything the Qibla screen needs to know about how trustworthy a heading is
/// on this device, in this place.
class CompassEnvironment {
  /// Magnetic declination in degrees east of true north.
  final double declination;

  /// Horizontal field intensity in nT, used for the polar reliability zones.
  final double horizontalIntensity;

  /// What the device's sensors are physically capable of.
  final CompassCapabilities capabilities;

  /// Whether the bundled magnetic model is still inside its validity window.
  final bool modelIsCurrent;

  /// Name of the bundled model, e.g. `WMM-2025`.
  final String modelName;

  const CompassEnvironment({
    required this.declination,
    required this.horizontalIntensity,
    required this.capabilities,
    required this.modelIsCurrent,
    required this.modelName,
  });

  CompassQuality get quality => capabilities.quality;

  bool get isBlackoutZone => horizontalIntensity < 2000;

  bool get isCautionZone =>
      horizontalIntensity >= 2000 && horizontalIntensity < 6000;
}

/// Resolves the declination and the device's compass capabilities.
///
/// The declination is computed in Dart from the bundled World Magnetic Model
/// rather than from `android.hardware.GeomagneticField`. The platform's copy is
/// baked into the OS image — AOSP still ships WMM-2020, which expired at the end
/// of 2025, and older devices carry older epochs again — so evaluating the model
/// in-app is what makes the correction identical on every device.
///
/// iOS reports `CLHeading.trueHeading`, which Core Location has already
/// corrected to true north, so the declination is not applied there.
class DeclinationService {
  static const MethodChannel _channel =
      MethodChannel('com.khushiidua.app/compass');

  /// Whether this platform's heading is already referenced to true north.
  static bool get platformReportsTrueNorth => !Platform.isAndroid;

  static Future<CompassEnvironment> resolve({
    required double latitude,
    required double longitude,
    DateTime? now,
  }) async {
    final WorldMagneticModel wmm = WorldMagneticModel.wmm2025();
    final double year =
        WorldMagneticModel.decimalYear(now ?? DateTime.now());

    final GeomagneticField field = wmm.calculate(
      latitude: latitude,
      longitude: longitude,
      decimalYear: year,
    );

    // iOS already hands back a true-north heading, so there is nothing to add.
    final double declination =
        platformReportsTrueNorth ? 0.0 : field.declination;

    debugPrint(
      '🧭 DeclinationService: ${wmm.model} @ ${year.toStringAsFixed(3)} '
      'declination=${field.declination.toStringAsFixed(3)}° '
      'applied=${declination.toStringAsFixed(3)}° '
      'H=${field.horizontalIntensity.toStringAsFixed(0)}nT',
    );

    return CompassEnvironment(
      declination: declination,
      horizontalIntensity: field.horizontalIntensity,
      capabilities: await _capabilities(),
      modelIsCurrent: wmm.isValidFor(year),
      modelName: wmm.model,
    );
  }

  static Future<CompassCapabilities> _capabilities() async {
    if (!Platform.isAndroid) return CompassCapabilities.unknown;

    try {
      final Map<Object?, Object?>? map =
          await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCompassCapabilities',
      );
      if (map == null) return CompassCapabilities.unknown;

      final CompassCapabilities capabilities =
          CompassCapabilities.fromMap(map);
      debugPrint(
        '🧭 DeclinationService: sensors '
        'mag=${capabilities.hasMagnetometer} '
        'accel=${capabilities.hasAccelerometer} '
        'rv=${capabilities.hasRotationVector} '
        'gyro=${capabilities.hasGyroscope} '
        '(${capabilities.rotationVectorName ?? 'no rotation vector'}) '
        '=> ${capabilities.quality.name}',
      );
      return capabilities;
    } on PlatformException catch (e) {
      debugPrint('🧭 DeclinationService: capability probe failed - ${e.message}');
      return CompassCapabilities.unknown;
    } on MissingPluginException {
      debugPrint('🧭 DeclinationService: compass channel not registered');
      return CompassCapabilities.unknown;
    }
  }
}
