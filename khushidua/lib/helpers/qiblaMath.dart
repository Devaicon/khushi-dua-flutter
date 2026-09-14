import 'dart:math' as math;

/// Pure geometry helpers for the Qibla compass.
///
/// The bearing produced by `Qibla.qibla()` is a great-circle bearing and is
/// therefore always referenced to **true north**. Device compass headings are
/// not: iOS reports `CLHeading.trueHeading` (true north) while the Android
/// implementation of `flutter_compass` reports the azimuth of the rotation
/// vector, which is referenced to **magnetic north**. Subtracting one from the
/// other without reconciling the references leaves an error equal to the
/// magnetic declination at the user's location.
///
/// Everything here is deliberately free of Flutter and sensor dependencies so
/// the angle handling can be exercised directly in unit tests.
class QiblaMath {
  const QiblaMath._();

  /// Normalises [angle] into the `[0, 360)` range.
  static double normalize(double angle) {
    final double mod = angle % 360.0;
    return mod < 0 ? mod + 360.0 : mod;
  }

  /// Converts a magnetic-north heading into a true-north heading.
  ///
  /// [declination] is degrees east of true north, matching the sign convention
  /// of `android.hardware.GeomagneticField.getDeclination()`.
  static double magneticToTrue(double magneticHeading, double declination) =>
      normalize(magneticHeading + declination);

  /// Angle the Qibla needle must be rotated by, clockwise from screen-up.
  ///
  /// Both arguments must already be referenced to true north.
  static double needleAngle(double qiblaTrue, double headingTrue) =>
      normalize(qiblaTrue - headingTrue);

  /// Smallest absolute angular difference between two bearings, in `[0, 180]`.
  static double angularDifference(double a, double b) {
    final double diff = normalize(a - b);
    return diff > 180 ? 360 - diff : diff;
  }

  /// Whether [needle] points within [tolerance] degrees of straight up.
  static bool isAligned(double needle, {double tolerance = 5}) =>
      angularDifference(needle, 0) <= tolerance;

  /// Whether a raw platform heading is a real reading.
  ///
  /// The two platforms use different ranges, and conflating them breaks the
  /// compass:
  ///
  /// * Android's `SensorManager.getOrientation` returns azimuth in
  ///   `[-180, 180]`, which `flutter_compass` forwards unmodified. A negative
  ///   heading there is an ordinary bearing between south and north via west.
  /// * iOS's `CLHeading.trueHeading` is `[0, 360)` and uses `-1` to signal that
  ///   true north could not be resolved.
  ///
  /// Pass [negativeMeansUnavailable] as `true` only on platforms that use the
  /// negative sentinel.
  static bool isHeadingUsable(
    double? heading, {
    required bool negativeMeansUnavailable,
  }) {
    if (heading == null) return false;
    if (!heading.isFinite) return false;
    if (negativeMeansUnavailable && heading < 0) return false;
    return true;
  }

  /// Degrees to radians.
  static double toRadians(double degrees) => degrees * math.pi / 180.0;
}
