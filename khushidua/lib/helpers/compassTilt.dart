import 'dart:math' as math;

/// Gravity as an accelerometer reports it, in screen axes: x to the right, y
/// to the top of the screen, z out of the screen, in m/s². It points away
/// from the ground, so a phone lying flat, face up, reads `(0, 0, 9.81)`.
class Gravity {
  final double x, y, z;

  const Gravity(this.x, this.y, this.z);

  /// Reads `[x, y, z]` from the platform; null if it is not three numbers.
  static Gravity? fromList(Object? value) {
    if (value is! List || value.length != 3) return null;
    final List<double> v = <double>[];
    for (final Object? n in value) {
      if (n is! num || !n.isFinite) return null;
      v.add(n.toDouble());
    }
    return Gravity(v[0], v[1], v[2]);
  }

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// How far the phone is from lying flat, face up.
class DeviceTilt {
  /// Radians the top edge is raised (positive) or lowered (negative).
  final double pitch;

  /// Radians the right edge is raised (positive) or lowered (negative).
  final double roll;

  /// Angle between the screen and the horizontal, in degrees: 0 flat face
  /// up, 90 upright, 180 face down.
  final double degrees;

  const DeviceTilt({
    required this.pitch,
    required this.roll,
    required this.degrees,
  });

  static const DeviceTilt flat = DeviceTilt(pitch: 0, roll: 0, degrees: 0);

  factory DeviceTilt.fromGravity(Gravity g) {
    final double m = g.magnitude;
    if (m < 1e-3) return flat;
    double angle(double component) =>
        math.asin((component / m).clamp(-1.0, 1.0));
    return DeviceTilt(
      pitch: angle(g.y),
      roll: angle(g.x),
      degrees: math.acos((g.z / m).clamp(-1.0, 1.0)) * 180 / math.pi,
    );
  }

  /// Moves a [factor] of the way towards [next], so the dial glides rather
  /// than shakes.
  DeviceTilt smoothTowards(DeviceTilt next, double factor) => DeviceTilt(
    pitch: pitch + (next.pitch - pitch) * factor,
    roll: roll + (next.roll - roll) * factor,
    degrees: degrees + (next.degrees - degrees) * factor,
  );

  /// Within [kFlatTolerance] of level.
  bool get isFlat => degrees <= kFlatTolerance;

  /// Where a level's bubble sits, as a fraction of its travel in screen
  /// coordinates (y down): it rises to the high side, so a raised top edge
  /// moves it up and a raised right edge moves it right.
  ({double dx, double dy}) get bubble {
    double dx = math.sin(roll) / math.sin(kMaxDialTilt);
    double dy = -math.sin(pitch) / math.sin(kMaxDialTilt);
    final double length = math.sqrt(dx * dx + dy * dy);
    if (length > 1) {
      dx /= length;
      dy /= length;
    }
    return (dx: dx, dy: dy);
  }
}

/// Counts as flat within this many degrees.
const double kFlatTolerance = 4;

/// Beyond this many degrees the user is asked to hold the phone flatter. The
/// heading is tilt-compensated, so only a phone held well up from flat needs
/// telling; the level shows any smaller lean.
const double kTiltWarning = 45;

/// The dial leans at most this far (radians), so it stays readable however
/// the phone is held.
const double kMaxDialTilt = 35 * math.pi / 180;
