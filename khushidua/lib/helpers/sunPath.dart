import 'dart:math' as math;

/// The shape of the sun-path view on the next-prayer card: a hill for the
/// daylight hours between two dips for the night either side of it.
///
/// Positions run 0–1 across the card. Sunrise sits at [riseX] and sunset at
/// [setX], so the hill is always the same width whatever the season; the
/// night is squeezed into the edges, midnight at each end.
abstract final class SunPath {
  static const double riseX = 0.14;
  static const double setX = 0.86;

  /// How deep the night dips, as a share of the hill's height.
  static const double nightDepth = 0.28;

  /// Height of the path at [x]: 0 on the horizon, 1 at the top of the hill,
  /// negative below the horizon.
  static double heightAt(double x) {
    if (x <= riseX) {
      return _night(1 - x / riseX);
    }
    if (x >= setX) {
      return _night((x - setX) / (1 - setX));
    }
    return math.sin(math.pi * (x - riseX) / (setX - riseX));
  }

  /// [u] is 0 at the horizon and 1 at midnight.
  static double _night(double u) =>
      -nightDepth * math.sin(math.pi / 2 * u.clamp(0.0, 1.0));

  /// Where the sun is at [now], given today's [sunrise] and [sunset]: the
  /// fraction of the way across, and whether it is up.
  static ({double x, bool isDay}) positionAt({
    required DateTime now,
    required DateTime sunrise,
    required DateTime sunset,
  }) {
    if (!now.isBefore(sunrise) && !now.isAfter(sunset)) {
      final t = _fraction(now, sunrise, sunset);
      return (x: riseX + t * (setX - riseX), isDay: true);
    }
    final midnight = DateTime(sunrise.year, sunrise.month, sunrise.day);
    if (now.isBefore(sunrise)) {
      final t = _fraction(now, midnight, sunrise);
      return (x: t * riseX, isDay: false);
    }
    final nextMidnight = DateTime(sunrise.year, sunrise.month, sunrise.day + 1);
    final t = _fraction(now, sunset, nextMidnight);
    return (x: setX + t * (1 - setX), isDay: false);
  }

  static double _fraction(DateTime now, DateTime from, DateTime to) {
    final span = to.difference(from).inSeconds;
    if (span <= 0) return 0;
    return (now.difference(from).inSeconds / span).clamp(0.0, 1.0);
  }
}
