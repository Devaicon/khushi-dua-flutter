import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/qiblaMath.dart';

void main() {
  group('normalize', () {
    test('leaves in-range angles untouched', () {
      expect(QiblaMath.normalize(0), 0);
      expect(QiblaMath.normalize(180), 180);
      expect(QiblaMath.normalize(359.9), closeTo(359.9, 1e-9));
    });

    test('wraps negatives into [0, 360)', () {
      expect(QiblaMath.normalize(-1), closeTo(359, 1e-9));
      expect(QiblaMath.normalize(-90), closeTo(270, 1e-9));
      expect(QiblaMath.normalize(-370), closeTo(350, 1e-9));
    });

    test('wraps values at or above 360', () {
      expect(QiblaMath.normalize(360), 0);
      expect(QiblaMath.normalize(450), closeTo(90, 1e-9));
    });
  });

  group('magneticToTrue', () {
    // GeomagneticField.getDeclination() is positive east of true north, so a
    // magnetic heading must have declination ADDED to become a true heading.
    test('east (positive) declination rotates the heading clockwise', () {
      // Auckland, roughly +20 deg east.
      expect(QiblaMath.magneticToTrue(0, 20), closeTo(20, 1e-9));
    });

    test('west (negative) declination rotates the heading anticlockwise', () {
      // New York, roughly -12.5 deg east (i.e. west).
      expect(QiblaMath.magneticToTrue(0, -13), closeTo(347, 1e-9));
    });

    test('is a no-op where declination is zero', () {
      expect(QiblaMath.magneticToTrue(123.4, 0), closeTo(123.4, 1e-9));
    });

    test('wraps across the 360 boundary', () {
      expect(QiblaMath.magneticToTrue(355, 10), closeTo(5, 1e-9));
    });
  });

  group('needleAngle', () {
    test('points straight up when already facing the Qibla', () {
      expect(QiblaMath.needleAngle(118.99, 118.99), closeTo(0, 1e-9));
    });

    test('points right when the Qibla is clockwise of the heading', () {
      expect(QiblaMath.needleAngle(90, 0), closeTo(90, 1e-9));
    });

    test('points left when the Qibla is anticlockwise of the heading', () {
      expect(QiblaMath.needleAngle(0, 90), closeTo(270, 1e-9));
    });

    test('London facing north points south-east toward Makkah', () {
      // Qibla.qibla() for London is 118.99 deg from true north.
      expect(QiblaMath.needleAngle(118.99, 0), closeTo(118.99, 1e-9));
    });
  });

  group('regression: magnetic vs true north', () {
    // The original bug: a magnetic heading was subtracted from a true-north
    // Qibla bearing, leaving an error equal to the local declination.
    test('uncorrected Android heading is wrong by exactly the declination', () {
      const double qiblaTrue = 58.49; // New York City.
      const double declination = -11.0; // Degrees east of true north.
      const double magneticHeading = 0.0; // Phone facing magnetic north.

      final double uncorrected = QiblaMath.needleAngle(qiblaTrue, magneticHeading);
      final double corrected = QiblaMath.needleAngle(
        qiblaTrue,
        QiblaMath.magneticToTrue(magneticHeading, declination),
      );

      expect(QiblaMath.angularDifference(uncorrected, corrected),
          closeTo(declination.abs(), 1e-9));
    });

    test('corrected needle matches the true bearing when facing true north', () {
      const double qiblaTrue = 58.49;
      const double declination = -11.0;
      // Facing TRUE north means the magnetometer reads +11 magnetic.
      const double magneticHeading = 11.0;

      final double corrected = QiblaMath.needleAngle(
        qiblaTrue,
        QiblaMath.magneticToTrue(magneticHeading, declination),
      );

      expect(corrected, closeTo(qiblaTrue, 1e-9));
    });
  });

  group('angularDifference', () {
    test('is symmetric', () {
      expect(QiblaMath.angularDifference(10, 350),
          closeTo(QiblaMath.angularDifference(350, 10), 1e-9));
    });

    test('takes the short way around the circle', () {
      expect(QiblaMath.angularDifference(10, 350), closeTo(20, 1e-9));
      expect(QiblaMath.angularDifference(0, 190), closeTo(170, 1e-9));
    });

    test('never exceeds 180', () {
      for (double a = 0; a < 360; a += 17) {
        for (double b = 0; b < 360; b += 23) {
          expect(QiblaMath.angularDifference(a, b), lessThanOrEqualTo(180));
        }
      }
    });
  });

  group('isAligned', () {
    test('accepts angles just inside the tolerance on both sides', () {
      expect(QiblaMath.isAligned(4.9), isTrue);
      expect(QiblaMath.isAligned(355.1), isTrue);
    });

    test('rejects angles outside the tolerance', () {
      expect(QiblaMath.isAligned(5.1), isFalse);
      expect(QiblaMath.isAligned(354.9), isFalse);
      expect(QiblaMath.isAligned(180), isFalse);
    });
  });

  group('isHeadingUsable', () {
    // Regression: Android's SensorManager.getOrientation returns azimuth in
    // [-180, 180], so any heading from south through west arrives negative.
    // Treating negative as "sensor unavailable" broke the compass on every
    // Android device for half of all bearings.
    test('Android negative azimuths are ordinary readings', () {
      for (final double h in <double>[-0.1, -45, -90, -179.9, -180]) {
        expect(
          QiblaMath.isHeadingUsable(h, negativeMeansUnavailable: false),
          isTrue,
          reason: '$h is a valid Android azimuth',
        );
      }
    });

    test('Android positive azimuths are usable', () {
      for (final double h in <double>[0, 90, 179.9, 180]) {
        expect(
          QiblaMath.isHeadingUsable(h, negativeMeansUnavailable: false),
          isTrue,
        );
      }
    });

    test('iOS treats negatives as the unavailable sentinel', () {
      // CLHeading.trueHeading is [0, 360) and reports -1 when it cannot
      // resolve true north.
      expect(
        QiblaMath.isHeadingUsable(-1, negativeMeansUnavailable: true),
        isFalse,
      );
      expect(
        QiblaMath.isHeadingUsable(0, negativeMeansUnavailable: true),
        isTrue,
      );
      expect(
        QiblaMath.isHeadingUsable(359.9, negativeMeansUnavailable: true),
        isTrue,
      );
    });

    test('null is never usable on any platform', () {
      expect(
        QiblaMath.isHeadingUsable(null, negativeMeansUnavailable: false),
        isFalse,
      );
      expect(
        QiblaMath.isHeadingUsable(null, negativeMeansUnavailable: true),
        isFalse,
      );
    });

    test('NaN and infinity are never usable', () {
      for (final double h in <double>[double.nan, double.infinity]) {
        expect(
          QiblaMath.isHeadingUsable(h, negativeMeansUnavailable: false),
          isFalse,
        );
      }
    });
  });

  group('regression: negative Android azimuth still points correctly', () {
    test('a -90 azimuth is the same bearing as 270', () {
      const double qibla = 260.31; // Lahore.
      final double fromNegative = QiblaMath.needleAngle(
        qibla,
        QiblaMath.magneticToTrue(-90, 2.2),
      );
      final double fromPositive = QiblaMath.needleAngle(
        qibla,
        QiblaMath.magneticToTrue(270, 2.2),
      );
      expect(fromNegative, closeTo(fromPositive, 1e-9));
    });
  });
}
