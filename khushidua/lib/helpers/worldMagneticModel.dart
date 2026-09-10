import 'dart:math' as math;

import 'wmmCoefficients.dart';

/// Result of a World Magnetic Model evaluation.
class GeomagneticField {
  /// Magnetic declination in degrees east of true north.
  final double declination;

  /// Horizontal field intensity in nT. Used to detect the polar regions where
  /// a magnetic compass stops being trustworthy at all.
  final double horizontalIntensity;

  const GeomagneticField({
    required this.declination,
    required this.horizontalIntensity,
  });

  /// NOAA defines H < 2000 nT as a "blackout zone" where declination values are
  /// inaccurate and compasses are unreliable.
  bool get isBlackoutZone => horizontalIntensity < 2000;

  /// NOAA defines 2000 nT <= H < 6000 nT as a "caution zone" where compass
  /// accuracy may be degraded.
  bool get isCautionZone =>
      horizontalIntensity >= 2000 && horizontalIntensity < 6000;
}

/// A pure-Dart implementation of the NOAA/NCEI World Magnetic Model.
///
/// The app carries its own model rather than calling
/// `android.hardware.GeomagneticField` because the platform's copy is tied to
/// the OS image: AOSP currently ships WMM-2020, whose validity ended in 2025,
/// and older devices carry older epochs still. Evaluating the model in Dart
/// means every device — new or old — uses the same current coefficients.
///
/// Ported from NOAA's reference `geomag` implementation (the same recursion used
/// by `geomag70.c` and its descendants). Validated against an independent
/// implementation across a global grid in `test/worldMagneticModel_test.dart`.
class WorldMagneticModel {
  // WGS84 ellipsoid, kilometres.
  static const double _a = 6378.137;
  static const double _b = 6356.7523142;

  /// Geomagnetic reference radius, kilometres.
  static const double _re = 6371.2;

  static const int _maxOrd = kWmmMaxOrder;
  static const int _size = _maxOrd + 1;

  /// Unnormalised Gauss coefficients, indexed `[m][n]` with `h` stored at
  /// `[n][m - 1]`, matching the reference implementation's packing.
  final List<List<double>> _c;
  final List<List<double>> _cd;

  /// Schmidt normalisation factors, flattened as `n + m * _size`.
  final List<double> _snorm;
  final List<List<double>> _k;
  final List<double> _fn;
  final List<double> _fm;

  WorldMagneticModel._(
    this._c,
    this._cd,
    this._snorm,
    this._k,
    this._fn,
    this._fm,
  );

  static WorldMagneticModel? _instance;

  /// The bundled WMM-2025 model. Built once and reused.
  factory WorldMagneticModel.wmm2025() => _instance ??= _build();

  /// Model name, e.g. `WMM-2025`.
  String get model => kWmmModel;

  /// Model epoch in decimal years.
  double get epoch => kWmmEpoch;

  /// First decimal year the model is no longer valid for.
  double get expiry => kWmmEpoch + 5.0;

  /// Whether [decimalYear] falls inside the model's five-year validity window.
  bool isValidFor(double decimalYear) =>
      decimalYear >= epoch && decimalYear < expiry;

  static List<List<double>> _matrix() =>
      List<List<double>>.generate(_size, (_) => List<double>.filled(_size, 0.0));

  static WorldMagneticModel _build() {
    final List<List<double>> c = _matrix();
    final List<List<double>> cd = _matrix();
    final List<double> snorm = List<double>.filled(_size * _size, 0.0);
    final List<double> fn = List<double>.filled(_size, 0.0);
    final List<double> fm = List<double>.filled(_size, 0.0);
    final List<List<double>> k = _matrix();

    for (final List<double> row in kWmmCoefficients) {
      final int n = row[0].toInt();
      final int m = row[1].toInt();
      if (m > _maxOrd || m > n) continue;
      c[m][n] = row[2];
      cd[m][n] = row[4];
      if (m != 0) {
        c[n][m - 1] = row[3];
        cd[n][m - 1] = row[5];
      }
    }

    // Convert Schmidt semi-normalised coefficients to unnormalised.
    snorm[0] = 1.0;
    fm[0] = 0.0;
    for (int n = 1; n <= _maxOrd; n++) {
      snorm[n] = snorm[n - 1] * (2 * n - 1) / n;
      int j = 2;
      for (int m = 0; m <= n; m++) {
        k[m][n] = (((n - 1) * (n - 1)) - (m * m)) / ((2 * n - 1) * (2 * n - 3));
        if (m > 0) {
          final double flnmj = ((n - m + 1) * j) / (n + m).toDouble();
          snorm[n + m * _size] = snorm[n + (m - 1) * _size] * math.sqrt(flnmj);
          j = 1;
          c[n][m - 1] = snorm[n + m * _size] * c[n][m - 1];
          cd[n][m - 1] = snorm[n + m * _size] * cd[n][m - 1];
        }
        c[m][n] = snorm[n + m * _size] * c[m][n];
        cd[m][n] = snorm[n + m * _size] * cd[m][n];
      }
      fn[n] = (n + 1).toDouble();
      fm[n] = n.toDouble();
    }
    k[1][1] = 0.0;

    return WorldMagneticModel._(c, cd, snorm, k, fn, fm);
  }

  /// Evaluates the model.
  ///
  /// [latitude] and [longitude] are geodetic degrees, [altitudeKm] is height
  /// above the WGS84 ellipsoid in kilometres, and [decimalYear] is the time as a
  /// decimal year (e.g. 2026.7).
  GeomagneticField calculate({
    required double latitude,
    required double longitude,
    required double decimalYear,
    double altitudeKm = 0,
  }) {
    final List<List<double>> tc = _matrix();
    final List<List<double>> dp = _matrix();
    final List<double> sp = List<double>.filled(_size, 0.0);
    final List<double> cp = List<double>.filled(_size, 0.0);
    final List<double> pp = List<double>.filled(_size, 0.0);
    // The Legendre recursion overwrites its working array, so start from a copy
    // of the normalisation factors rather than mutating the shared model state.
    final List<double> p = List<double>.of(_snorm);

    sp[0] = 0.0;
    cp[0] = 1.0;
    pp[0] = 1.0;
    dp[0][0] = 0.0;

    const double a2 = _a * _a;
    const double b2 = _b * _b;
    const double c2 = a2 - b2;
    const double a4 = a2 * a2;
    const double b4 = b2 * b2;
    const double c4 = a4 - b4;

    final double dt = decimalYear - kWmmEpoch;

    final double rlon = longitude * math.pi / 180.0;
    final double rlat = latitude * math.pi / 180.0;
    final double srlon = math.sin(rlon);
    final double crlon = math.cos(rlon);
    final double srlat = math.sin(rlat);
    final double crlat = math.cos(rlat);
    final double srlat2 = srlat * srlat;
    final double crlat2 = crlat * crlat;
    sp[1] = srlon;
    cp[1] = crlon;

    // Geodetic to geocentric spherical coordinates.
    final double q = math.sqrt(a2 - c2 * srlat2);
    final double q1 = altitudeKm * q;
    final double q2 =
        ((q1 + a2) / (q1 + b2)) * ((q1 + a2) / (q1 + b2));
    final double ct = srlat / math.sqrt(q2 * crlat2 + srlat2);
    final double st = math.sqrt(1.0 - (ct * ct));
    final double r2 = (altitudeKm * altitudeKm) +
        2.0 * q1 +
        (a4 - c4 * srlat2) / (q * q);
    final double r = math.sqrt(r2);
    final double d = math.sqrt(a2 * crlat2 + b2 * srlat2);
    final double ca = (altitudeKm + d) / r;
    final double sa = c2 * crlat * srlat / (r * d);

    for (int m = 2; m <= _maxOrd; m++) {
      sp[m] = sp[1] * cp[m - 1] + cp[1] * sp[m - 1];
      cp[m] = cp[1] * cp[m - 1] - sp[1] * sp[m - 1];
    }

    final double aor = _re / r;
    double ar = aor * aor;
    double br = 0.0;
    double bt = 0.0;
    double bp = 0.0;
    double bpp = 0.0;

    for (int n = 1; n <= _maxOrd; n++) {
      ar = ar * aor;
      for (int m = 0; m <= n; m++) {
        // Unnormalised associated Legendre polynomials and their derivatives.
        if (n == m) {
          p[n + m * _size] = st * p[n - 1 + (m - 1) * _size];
          dp[m][n] = st * dp[m - 1][n - 1] + ct * p[n - 1 + (m - 1) * _size];
        } else if (n == 1 && m == 0) {
          p[n + m * _size] = ct * p[n - 1 + m * _size];
          dp[m][n] = ct * dp[m][n - 1] - st * p[n - 1 + m * _size];
        } else if (n > 1 && n != m) {
          if (m > n - 2) {
            p[n - 2 + m * _size] = 0.0;
            dp[m][n - 2] = 0.0;
          }
          p[n + m * _size] =
              ct * p[n - 1 + m * _size] - _k[m][n] * p[n - 2 + m * _size];
          dp[m][n] = ct * dp[m][n - 1] -
              st * p[n - 1 + m * _size] -
              _k[m][n] * dp[m][n - 2];
        }

        // Time-adjust the Gauss coefficients.
        tc[m][n] = _c[m][n] + dt * _cd[m][n];
        if (m != 0) {
          tc[n][m - 1] = _c[n][m - 1] + dt * _cd[n][m - 1];
        }

        // Accumulate terms of the spherical harmonic expansion.
        final double par = ar * p[n + m * _size];
        final double temp1;
        final double temp2;
        if (m == 0) {
          temp1 = tc[m][n] * cp[m];
          temp2 = tc[m][n] * sp[m];
        } else {
          temp1 = tc[m][n] * cp[m] + tc[n][m - 1] * sp[m];
          temp2 = tc[m][n] * sp[m] - tc[n][m - 1] * cp[m];
        }
        bt = bt - ar * temp1 * dp[m][n];
        bp += _fm[m] * temp2 * par;
        br += _fn[n] * temp1 * par;

        // Special case: geographic north/south poles.
        if (st == 0.0 && m == 1) {
          if (n == 1) {
            pp[n] = pp[n - 1];
          } else {
            pp[n] = ct * pp[n - 1] - _k[m][n] * pp[n - 2];
          }
          final double parp = ar * pp[n];
          bpp += _fm[m] * temp2 * parp;
        }
      }
    }

    if (st == 0.0) {
      bp = bpp;
    } else {
      bp /= st;
    }

    // Rotate from spherical back to geodetic coordinates.
    final double bx = -bt * ca - br * sa;
    final double by = bp;

    final double bh = math.sqrt((bx * bx) + (by * by));

    return GeomagneticField(
      declination: math.atan2(by, bx) * 180.0 / math.pi,
      horizontalIntensity: bh,
    );
  }

  /// Converts a [DateTime] to the decimal year the model expects.
  static double decimalYear(DateTime date) {
    final DateTime utc = date.toUtc();
    final int year = utc.year;
    final DateTime start = DateTime.utc(year);
    final DateTime end = DateTime.utc(year + 1);
    final double fraction = utc.difference(start).inSeconds /
        end.difference(start).inSeconds;
    return year + fraction;
  }
}
