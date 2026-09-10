import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/compassQuality.dart';

CompassCapabilities caps({
  bool magnetometer = true,
  bool accelerometer = true,
  bool rotationVector = true,
  bool geomagneticRotationVector = true,
  bool gyroscope = true,
}) =>
    CompassCapabilities(
      hasMagnetometer: magnetometer,
      hasAccelerometer: accelerometer,
      hasRotationVector: rotationVector,
      hasGeomagneticRotationVector: geomagneticRotationVector,
      hasGyroscope: gyroscope,
    );

void main() {
  group('quality classification', () {
    test('modern phone with rotation vector and gyroscope is high', () {
      expect(caps().quality, CompassQuality.high);
    });

    test('rotation vector without a gyroscope is reduced', () {
      expect(caps(gyroscope: false).quality, CompassQuality.reduced);
    });

    test('no rotation vector falls back to magnetometer plus accelerometer', () {
      // This is the old-Android path flutter_compass actually takes.
      expect(caps(rotationVector: false).quality, CompassQuality.low);
    });

    test('no rotation vector and no gyroscope is still low, not reduced', () {
      expect(
        caps(rotationVector: false, gyroscope: false).quality,
        CompassQuality.low,
      );
    });

    test('no magnetometer is unavailable regardless of other sensors', () {
      expect(caps(magnetometer: false).quality, CompassQuality.unavailable);
      expect(
        caps(magnetometer: false, rotationVector: false).quality,
        CompassQuality.unavailable,
      );
    });

    test('magnetometer without accelerometer or rotation vector is unavailable',
        () {
      expect(
        caps(rotationVector: false, accelerometer: false).quality,
        CompassQuality.unavailable,
      );
    });

    test('unknown capabilities default to a usable device', () {
      // iOS reports a fused true-north heading and no inventory; it should not
      // be warned about.
      expect(CompassCapabilities.unknown.quality, CompassQuality.high);
    });
  });

  group('fromMap', () {
    test('reads the platform payload', () {
      final CompassCapabilities c = CompassCapabilities.fromMap(
        <Object?, Object?>{
          'hasMagnetometer': true,
          'hasAccelerometer': true,
          'hasRotationVector': false,
          'hasGeomagneticRotationVector': false,
          'hasGyroscope': false,
          'rotationVectorName': null,
        },
      );
      expect(c.hasMagnetometer, isTrue);
      expect(c.hasRotationVector, isFalse);
      expect(c.quality, CompassQuality.low);
    });

    test('missing keys are treated as absent sensors', () {
      final CompassCapabilities c =
          CompassCapabilities.fromMap(<Object?, Object?>{});
      expect(c.quality, CompassQuality.unavailable);
    });
  });

  group('messages', () {
    test('high and unknown say nothing', () {
      expect(CompassQualityMessage.forQuality(CompassQuality.high), isNull);
      expect(CompassQualityMessage.forQuality(CompassQuality.unknown), isNull);
    });

    test('degraded states all explain the limitation', () {
      for (final CompassQuality q in <CompassQuality>[
        CompassQuality.reduced,
        CompassQuality.low,
        CompassQuality.unavailable,
      ]) {
        final String? message = CompassQualityMessage.forQuality(q);
        expect(message, isNotNull, reason: '$q should warn the user');
        expect(message!.length, greaterThan(30));
      }
    });

    test('only unavailable hides the heading', () {
      expect(CompassQualityMessage.canShowHeading(CompassQuality.high), isTrue);
      expect(CompassQualityMessage.canShowHeading(CompassQuality.reduced), isTrue);
      expect(CompassQualityMessage.canShowHeading(CompassQuality.low), isTrue);
      expect(
        CompassQualityMessage.canShowHeading(CompassQuality.unavailable),
        isFalse,
      );
    });
  });
}
