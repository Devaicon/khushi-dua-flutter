/// How well the device's hardware can actually measure a compass heading.
///
/// The app applies the current World Magnetic Model on every device, so the
/// declination correction is no longer device-dependent. What remains
/// device-dependent is the *sensor* side, and no amount of software can fix a
/// missing or low-grade sensor. This enum classifies that residual limitation so
/// it can be shown to the user rather than silently degrading their heading.
enum CompassQuality {
  /// A fused rotation-vector sensor backed by a gyroscope. Best available.
  high,

  /// A rotation vector without gyroscope backing, so the heading comes from a
  /// geomagnetic-only fusion that drifts and lags more.
  reduced,

  /// No rotation-vector sensor at all: the heading is derived from the raw
  /// magnetometer and accelerometer, which is noisy and tilt-sensitive.
  low,

  /// No magnetometer. A compass heading is not physically possible.
  unavailable,

  /// Capabilities were not reported. iOS falls here: it exposes a fused,
  /// true-north heading and does not surface the underlying sensor inventory.
  unknown,
}

/// The sensor inventory reported by the platform.
class CompassCapabilities {
  final bool hasMagnetometer;
  final bool hasAccelerometer;
  final bool hasRotationVector;
  final bool hasGeomagneticRotationVector;
  final bool hasGyroscope;

  /// Human-readable sensor name, for diagnostics only.
  final String? rotationVectorName;

  const CompassCapabilities({
    required this.hasMagnetometer,
    required this.hasAccelerometer,
    required this.hasRotationVector,
    required this.hasGeomagneticRotationVector,
    required this.hasGyroscope,
    this.rotationVectorName,
  });

  /// Used when the platform does not report an inventory.
  static const CompassCapabilities unknown = CompassCapabilities(
    hasMagnetometer: true,
    hasAccelerometer: true,
    hasRotationVector: true,
    hasGeomagneticRotationVector: true,
    hasGyroscope: true,
    rotationVectorName: null,
  );

  factory CompassCapabilities.fromMap(Map<Object?, Object?> map) {
    bool flag(String key) => map[key] == true;
    return CompassCapabilities(
      hasMagnetometer: flag('hasMagnetometer'),
      hasAccelerometer: flag('hasAccelerometer'),
      hasRotationVector: flag('hasRotationVector'),
      hasGeomagneticRotationVector: flag('hasGeomagneticRotationVector'),
      hasGyroscope: flag('hasGyroscope'),
      rotationVectorName: map['rotationVectorName'] as String?,
    );
  }

  /// Classifies the hardware.
  ///
  /// Mirrors how `flutter_compass` actually reads the device: it prefers
  /// `TYPE_ROTATION_VECTOR` and falls back to `TYPE_ACCELEROMETER` plus
  /// `TYPE_MAGNETIC_FIELD` when that sensor is absent.
  CompassQuality get quality {
    // Every path the plugin can take needs the magnetometer.
    if (!hasMagnetometer) return CompassQuality.unavailable;

    if (hasRotationVector) {
      // A rotation vector without a gyroscope is a geomagnetic-only fusion.
      return hasGyroscope ? CompassQuality.high : CompassQuality.reduced;
    }

    // Plugin falls back to raw accelerometer + magnetometer.
    if (hasAccelerometer) return CompassQuality.low;

    return CompassQuality.unavailable;
  }
}

/// User-facing copy for each hardware limitation.
///
/// Deliberately explains that the limit is the device, not the app, so the user
/// understands the reading is as good as their hardware allows.
class CompassQualityMessage {
  const CompassQualityMessage._();

  /// Returns `null` when there is nothing worth telling the user.
  static String? forQuality(CompassQuality quality) {
    switch (quality) {
      case CompassQuality.high:
      case CompassQuality.unknown:
        return null;
      case CompassQuality.reduced:
        return 'Your device has no gyroscope, so its heading comes from the '
            'magnetometer alone. The direction is accurate but may drift or '
            'lag as you turn.';
      case CompassQuality.low:
        return 'Your device has no rotation-vector sensor, so the heading is '
            'measured with the magnetometer and accelerometer alone. Hold the '
            'phone flat and away from metal or magnets for the best reading.';
      case CompassQuality.unavailable:
        return 'This device has no magnetic compass sensor, so it cannot '
            'measure which way you are facing. Use the Qibla angle shown below '
            'with a separate compass.';
    }
  }

  /// Whether the heading can be shown at all.
  static bool canShowHeading(CompassQuality quality) =>
      quality != CompassQuality.unavailable;
}
