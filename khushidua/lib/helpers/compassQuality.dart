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
  /// Mirrors how the Android heading stream reads the device: Google's fused
  /// orientation needs all three sensors, after which it uses
  /// `TYPE_ROTATION_VECTOR`, then `TYPE_ACCELEROMETER` plus
  /// `TYPE_MAGNETIC_FIELD`.
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

/// Above this heading error, in degrees, the user is asked to calibrate.
///
/// Facing the Qibla is generally accepted within 45° either side, so an
/// error up to here still leaves the user facing the right way. A tighter
/// line flags ordinary readings: Google's fused orientation commonly settles
/// at 30–40° even outdoors on some phones.
const double kPoorHeadingError = 40;

/// Once poor, a heading counts as recovered only at this error or better, so
/// an estimate hovering at the line does not toggle the prompt.
const double kRecoveredHeadingError = 35;

/// At or above this, a heading error is the platform saying it has no
/// estimate yet (the fused provider sends 180), not that the heading is bad.
const double kNoEstimateError = 179;

/// Whether the heading is too uncertain to point at the Qibla, given whether
/// it already was ([wasPoor]); null when there is nothing to judge by.
///
/// [errorDegrees] is the platform's estimate in degrees: the Fused
/// Orientation Provider's heading error, the rotation vector's `values[4]`, or
/// Core Location's `headingAccuracy`. It is preferred whenever present, except
/// at [kNoEstimateError]: the fused provider reports 180 before it has any
/// estimate, which is no reading at all rather than a poor one.
///
/// [magnetometerStatus] (`SensorManager.SENSOR_STATUS_*`) is the fallback.
/// It describes the magnetometer's calibration, not the heading: many devices
/// report `ACCURACY_LOW` (1) indefinitely while their fused heading is fine,
/// so only `UNRELIABLE` (0) counts as poor. Reading low as "uncalibrated" is
/// what kept the figure-8 prompt on screen for good.
bool? isPoorHeading({
  double? errorDegrees,
  int? magnetometerStatus,
  required bool wasPoor,
}) {
  final error = errorDegrees;
  if (error != null &&
      error.isFinite &&
      error >= 0 &&
      error < kNoEstimateError) {
    return error > (wasPoor ? kRecoveredHeadingError : kPoorHeadingError);
  }
  return switch (magnetometerStatus) {
    0 => true,
    1 || 2 || 3 => false,
    _ => null,
  };
}

/// How far the field the magnetometer measures is from what Earth's field
/// should be here, as a fraction: 0.4 is 40% stronger or weaker.
///
/// A calibrated magnetometer away from interference reads within a few
/// percent of the model. A large gap means a magnet, metal or electronics
/// nearby, or a magnetometer whose calibration has not converged; either way
/// its heading cannot be trusted.
double fieldDeviation({
  required double measuredMicroTesla,
  required double expectedNanoTesla,
}) {
  if (expectedNanoTesla <= 0) return 0;
  return (measuredMicroTesla * 1000 - expectedNanoTesla).abs() /
      expectedNanoTesla;
}

/// Beyond this [fieldDeviation] the user is told about interference, and it
/// clears again below [kFieldDeviationClear]. Steel-framed buildings alone
/// account for up to ~20%.
const double kFieldDeviationWarn = 0.35;
const double kFieldDeviationClear = 0.25;

/// A condition that only counts once it has held for [dwell], and only clears
/// once its opposite has held for [clearDwell] (by default the same).
///
/// Readings are noisy and settle over a few seconds after the screen opens,
/// so a notice that followed every reading would flash on and off.
class SustainedFlag {
  SustainedFlag({this.dwell = const Duration(seconds: 2), Duration? clearDwell})
    : clearDwell = clearDwell ?? dwell;

  final Duration dwell;
  final Duration clearDwell;

  bool _value = false;
  DateTime? _since;

  bool get value => _value;

  /// Records whether the condition holds [now]; returns true when [value]
  /// changes.
  bool update(bool condition, DateTime now) {
    if (condition == _value) {
      _since = null;
      return false;
    }
    final since = _since ??= now;
    if (now.difference(since) < (condition ? dwell : clearDwell)) return false;
    _value = condition;
    _since = null;
    return true;
  }
}
