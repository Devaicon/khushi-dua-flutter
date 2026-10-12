import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/services/headingService.dart';

void main() {
  group('HeadingReading.fromAndroid', () {
    test('reads a fused, true-north event', () {
      final reading = HeadingReading.fromAndroid({
        'heading': 271.5,
        'reference': 'true',
        'source': 'fused',
        'errorDegrees': 7.0,
        'magnetometerStatus': 1,
        'fieldMicroTesla': 48.2,
      })!;
      expect(reading.heading, 271.5);
      expect(reading.reference, HeadingReference.trueNorth);
      expect(reading.source, HeadingSource.fusedOrientation);
      expect(reading.errorDegrees, 7.0);
      expect(reading.magnetometerStatus, 1);
      expect(reading.fieldMicroTesla, 48.2);
    });

    test('reads a magnetic rotation-vector event without an estimate', () {
      final reading = HeadingReading.fromAndroid({
        'heading': 10,
        'reference': 'magnetic',
        'source': 'rotationVector',
        'errorDegrees': null,
        'magnetometerStatus': 3,
        'fieldMicroTesla': null,
      })!;
      expect(reading.heading, 10.0);
      expect(reading.reference, HeadingReference.magneticNorth);
      expect(reading.source, HeadingSource.rotationVector);
      expect(reading.errorDegrees, isNull);
      expect(reading.fieldMicroTesla, isNull);
    });

    test('reads gravity when sent, and none when not', () {
      final reading = HeadingReading.fromAndroid({
        'heading': 10.0,
        'gravity': [0.1, 0.2, 9.8],
      })!;
      expect(reading.gravity!.z, 9.8);
      expect(HeadingReading.fromAndroid({'heading': 10.0})!.gravity, isNull);
    });

    test('reads the accelerometer + magnetometer source', () {
      final reading = HeadingReading.fromAndroid({
        'heading': 90.0,
        'reference': 'magnetic',
        'source': 'accelMag',
      })!;
      expect(reading.source, HeadingSource.accelMag);
    });

    test('an unknown reference is treated as magnetic, never true', () {
      // Skipping declination silently would be the worse failure.
      final reading = HeadingReading.fromAndroid({'heading': 90.0})!;
      expect(reading.reference, HeadingReference.magneticNorth);
    });

    test('wraps the heading into [0, 360)', () {
      expect(HeadingReading.fromAndroid({'heading': 360.0})!.heading, 0);
      expect(HeadingReading.fromAndroid({'heading': -90.0})!.heading, 270);
    });

    test('an event without a usable heading is null', () {
      expect(HeadingReading.fromAndroid(null), isNull);
      expect(HeadingReading.fromAndroid([1.0, 2.0]), isNull);
      expect(HeadingReading.fromAndroid({'reference': 'true'}), isNull);
      expect(HeadingReading.fromAndroid({'heading': double.nan}), isNull);
    });
  });

  group('HeadingReading.fromIos', () {
    test('Core Location headings are true north with their accuracy', () {
      final reading = HeadingReading.fromIos(heading: 123.4, accuracy: 12)!;
      expect(reading.heading, 123.4);
      expect(reading.reference, HeadingReference.trueNorth);
      expect(reading.source, HeadingSource.coreLocation);
      expect(reading.errorDegrees, 12);
    });

    test('-1 means true north could not be resolved', () {
      expect(HeadingReading.fromIos(heading: -1, accuracy: 10), isNull);
      expect(HeadingReading.fromIos(heading: null, accuracy: 10), isNull);
    });
  });
}
