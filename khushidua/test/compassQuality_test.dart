import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/compassQuality.dart';

CompassCapabilities caps({
  bool magnetometer = true,
  bool accelerometer = true,
  bool rotationVector = true,
  bool geomagneticRotationVector = true,
  bool gyroscope = true,
}) => CompassCapabilities(
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

    test(
      'no rotation vector falls back to magnetometer plus accelerometer',
      () {
        // This is the old-Android path flutter_compass actually takes.
        expect(caps(rotationVector: false).quality, CompassQuality.low);
      },
    );

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

    test(
      'magnetometer without accelerometer or rotation vector is unavailable',
      () {
        expect(
          caps(rotationVector: false, accelerometer: false).quality,
          CompassQuality.unavailable,
        );
      },
    );

    test('unknown capabilities default to a usable device', () {
      // iOS reports a fused true-north heading and no inventory; it should not
      // be warned about.
      expect(CompassCapabilities.unknown.quality, CompassQuality.high);
    });
  });

  group('fromMap', () {
    test('reads the platform payload', () {
      final CompassCapabilities c =
          CompassCapabilities.fromMap(<Object?, Object?>{
            'hasMagnetometer': true,
            'hasAccelerometer': true,
            'hasRotationVector': false,
            'hasGeomagneticRotationVector': false,
            'hasGyroscope': false,
            'rotationVectorName': null,
          });
      expect(c.hasMagnetometer, isTrue);
      expect(c.hasRotationVector, isFalse);
      expect(c.quality, CompassQuality.low);
    });

    test('missing keys are treated as absent sensors', () {
      final CompassCapabilities c = CompassCapabilities.fromMap(
        <Object?, Object?>{},
      );
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
      expect(
        CompassQualityMessage.canShowHeading(CompassQuality.reduced),
        isTrue,
      );
      expect(CompassQualityMessage.canShowHeading(CompassQuality.low), isTrue);
      expect(
        CompassQualityMessage.canShowHeading(CompassQuality.unavailable),
        isFalse,
      );
    });
  });

  group('isPoorHeading', () {
    test('turns poor only above the poor line', () {
      expect(isPoorHeading(errorDegrees: 12, wasPoor: false), isFalse);
      expect(isPoorHeading(errorDegrees: 38, wasPoor: false), isFalse);
      expect(isPoorHeading(errorDegrees: 40, wasPoor: false), isFalse);
      expect(isPoorHeading(errorDegrees: 41, wasPoor: false), isTrue);
    });

    test('recovers only at the recovered line or better', () {
      expect(isPoorHeading(errorDegrees: 38, wasPoor: true), isTrue);
      expect(isPoorHeading(errorDegrees: 35.5, wasPoor: true), isTrue);
      expect(isPoorHeading(errorDegrees: 35, wasPoor: true), isFalse);
      expect(isPoorHeading(errorDegrees: 10, wasPoor: true), isFalse);
    });

    test('the error estimate wins over the magnetometer status', () {
      // The case that kept the prompt up for good: a fused heading within a
      // few degrees while the magnetometer still says "low".
      expect(
        isPoorHeading(errorDegrees: 6, magnetometerStatus: 1, wasPoor: false),
        isFalse,
      );
      expect(
        isPoorHeading(errorDegrees: 60, magnetometerStatus: 3, wasPoor: false),
        isTrue,
      );
    });

    test('without an estimate, only an unreliable magnetometer is poor', () {
      for (final status in [1, 2, 3]) {
        expect(
          isPoorHeading(magnetometerStatus: status, wasPoor: true),
          isFalse,
        );
      }
      expect(isPoorHeading(magnetometerStatus: 0, wasPoor: false), isTrue);
    });

    test('nothing to go on, or nonsense, is unknown', () {
      expect(isPoorHeading(wasPoor: false), isNull);
      expect(isPoorHeading(magnetometerStatus: -1, wasPoor: false), isNull);
      expect(isPoorHeading(errorDegrees: -1, wasPoor: false), isNull);
      expect(isPoorHeading(errorDegrees: double.nan, wasPoor: false), isNull);
    });

    test('180, the fused provider\'s "no estimate yet", is not poor', () {
      // A fresh fused registration can start at 180; counting that as poor
      // raised the prompt for no reason.
      expect(isPoorHeading(errorDegrees: 180, wasPoor: false), isNull);
      expect(
        isPoorHeading(errorDegrees: 180, magnetometerStatus: 3, wasPoor: false),
        isFalse,
      );
    });

    test('a nonsense estimate falls back to the status', () {
      expect(
        isPoorHeading(errorDegrees: -1, magnetometerStatus: 0, wasPoor: false),
        isTrue,
      );
    });
  });

  group('fieldDeviation', () {
    test('a field matching the model deviates by nothing', () {
      expect(
        fieldDeviation(measuredMicroTesla: 50, expectedNanoTesla: 50000),
        closeTo(0, 1e-9),
      );
    });

    test('is symmetric in stronger and weaker fields', () {
      expect(
        fieldDeviation(measuredMicroTesla: 70, expectedNanoTesla: 50000),
        closeTo(0.4, 1e-9),
      );
      expect(
        fieldDeviation(measuredMicroTesla: 30, expectedNanoTesla: 50000),
        closeTo(0.4, 1e-9),
      );
    });

    test('a magnet next to the phone is far outside the warning band', () {
      expect(
        fieldDeviation(measuredMicroTesla: 400, expectedNanoTesla: 48000),
        greaterThan(kFieldDeviationWarn),
      );
    });

    test('no model value is no deviation', () {
      expect(fieldDeviation(measuredMicroTesla: 50, expectedNanoTesla: 0), 0);
    });
  });

  group('SustainedFlag', () {
    final DateTime t0 = DateTime(2026);
    DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

    test('starts false', () {
      expect(SustainedFlag().value, isFalse);
    });

    test('sets only once the condition has held for the dwell', () {
      final flag = SustainedFlag(dwell: const Duration(seconds: 2));
      expect(flag.update(true, at(0)), isFalse);
      expect(flag.update(true, at(1500)), isFalse);
      expect(flag.value, isFalse);
      expect(flag.update(true, at(2000)), isTrue);
      expect(flag.value, isTrue);
    });

    test('a brief blip does not set it', () {
      final flag = SustainedFlag(dwell: const Duration(seconds: 2));
      flag.update(true, at(0));
      flag.update(false, at(500));
      flag.update(true, at(1000));
      flag.update(true, at(2500));
      expect(flag.value, isFalse);
      flag.update(true, at(3000));
      expect(flag.value, isTrue);
    });

    test('can clear faster than it sets', () {
      final flag = SustainedFlag(
        dwell: const Duration(seconds: 2),
        clearDwell: const Duration(milliseconds: 800),
      );
      flag.update(true, at(0));
      flag.update(true, at(2000));
      expect(flag.value, isTrue);
      flag.update(false, at(2100));
      expect(flag.update(false, at(2900)), isTrue);
      expect(flag.value, isFalse);
    });

    test('clears only once the opposite has held for the dwell', () {
      final flag = SustainedFlag(dwell: const Duration(seconds: 2));
      flag.update(true, at(0));
      flag.update(true, at(2000));
      expect(flag.value, isTrue);
      flag.update(false, at(2100));
      flag.update(false, at(3000));
      expect(flag.value, isTrue);
      expect(flag.update(false, at(4100)), isTrue);
      expect(flag.value, isFalse);
    });
  });
}
