import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../helpers/compassTilt.dart';
import '../helpers/qiblaMath.dart';

/// Which north a heading is measured from.
enum HeadingReference { trueNorth, magneticNorth }

/// What produced a heading.
enum HeadingSource {
  /// Google Play services' Fused Orientation Provider (Android).
  fusedOrientation,

  /// The platform rotation vector (Android, no Play services).
  rotationVector,

  /// Accelerometer plus magnetometer (Android, no rotation vector).
  accelMag,

  /// Core Location's `trueHeading` (iOS).
  coreLocation,
}

/// One heading from the platform, with what it is referenced to and how far
/// the platform trusts it.
class HeadingReading {
  /// Degrees clockwise from [reference], in `[0, 360)`.
  final double heading;
  final HeadingReference reference;
  final HeadingSource source;

  /// The platform's own error estimate in degrees, when it gives one.
  final double? errorDegrees;

  /// Android only: the magnetometer's `SensorManager.SENSOR_STATUS_*`.
  final int? magnetometerStatus;

  /// Android only: the strength of the field the magnetometer measures.
  final double? fieldMicroTesla;

  /// Android only: diagnostics were switched on natively, so log in any build.
  final bool verbose;

  /// Android only: gravity in screen axes, for the tilt of the dial.
  final Gravity? gravity;

  const HeadingReading({
    required this.heading,
    required this.reference,
    required this.source,
    this.errorDegrees,
    this.magnetometerStatus,
    this.fieldMicroTesla,
    this.verbose = false,
    this.gravity,
  });

  /// Reads an event from `HeadingStreamHandler.kt`; null if it holds no
  /// usable heading.
  static HeadingReading? fromAndroid(Object? event) {
    if (event is! Map) return null;
    final heading = (event['heading'] as num?)?.toDouble();
    if (heading == null || !heading.isFinite) return null;
    return HeadingReading(
      heading: QiblaMath.normalize(heading),
      // Anything but an explicit "true" is treated as magnetic, the
      // platform sensors' frame, so declination is never silently skipped.
      reference: event['reference'] == 'true'
          ? HeadingReference.trueNorth
          : HeadingReference.magneticNorth,
      source: switch (event['source']) {
        'fused' => HeadingSource.fusedOrientation,
        'accelMag' => HeadingSource.accelMag,
        _ => HeadingSource.rotationVector,
      },
      errorDegrees: (event['errorDegrees'] as num?)?.toDouble(),
      magnetometerStatus: (event['magnetometerStatus'] as num?)?.toInt(),
      fieldMicroTesla: (event['fieldMicroTesla'] as num?)?.toDouble(),
      verbose: event['verbose'] == true,
      gravity: Gravity.fromList(event['gravity']),
    );
  }

  /// Reads a `flutter_compass` event on iOS; null if Core Location could not
  /// resolve true north (it sends -1 then).
  static HeadingReading? fromIos({double? heading, double? accuracy}) {
    if (!QiblaMath.isHeadingUsable(heading, negativeMeansUnavailable: true)) {
      return null;
    }
    return HeadingReading(
      heading: QiblaMath.normalize(heading!),
      reference: HeadingReference.trueNorth,
      source: HeadingSource.coreLocation,
      errorDegrees: accuracy,
    );
  }
}

/// The device heading for the Qibla screen.
///
/// Android reads it from the app's own native stream (see
/// `HeadingStreamHandler.kt`), which prefers Google's Fused Orientation
/// Provider. iOS keeps `flutter_compass`, which reports Core Location's true
/// heading and was already correct.
class HeadingService {
  const HeadingService._();

  static const EventChannel _android = EventChannel(
    'com.khushiidua.app/heading',
  );

  /// One platform subscription, shared by every listener. A screen being
  /// replaced must not stop the sensors under its replacement: with a stream
  /// per listener, the new screen's listen reached the platform before the
  /// old screen's cancel, which then stopped the native side for both.
  static final Stream<HeadingReading?> _events = Platform.isAndroid
      ? _android.receiveBroadcastStream().map(HeadingReading.fromAndroid)
      : (FlutterCompass.events ?? const Stream<CompassEvent>.empty()).map(
          (event) => HeadingReading.fromIos(
            heading: event.heading,
            accuracy: event.accuracy,
          ),
        );

  /// Readings as they arrive; a null is a reading the platform marked
  /// unusable. Sensors run only while the stream is listened to.
  static Stream<HeadingReading?> events() => _events;

  /// Gravity in screen axes, for the dial's tilt. Android sends it with the
  /// heading, from the gyro-fused gravity sensor; iOS reads CoreMotion's
  /// accelerometer, which `sensors_plus` reports with Android's signs.
  static Stream<Gravity> gravity() {
    if (Platform.isAndroid) {
      return _events
          .map((reading) => reading?.gravity)
          .where((gravity) => gravity != null)
          .cast<Gravity>();
    }
    return accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).map((e) => Gravity(e.x, e.y, e.z));
  }
}
