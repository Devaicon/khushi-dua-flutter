import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/compassTilt.dart';

void main() {
  const double g = 9.81;
  double rad(double deg) => deg * math.pi / 180;

  group('Gravity.fromList', () {
    test('reads three numbers', () {
      final gravity = Gravity.fromList([0.5, -1, 9.7])!;
      expect([gravity.x, gravity.y, gravity.z], [0.5, -1.0, 9.7]);
    });

    test('anything else is null', () {
      expect(Gravity.fromList(null), isNull);
      expect(Gravity.fromList([1.0, 2.0]), isNull);
      expect(Gravity.fromList([1.0, 'x', 3.0]), isNull);
      expect(Gravity.fromList([1.0, double.nan, 3.0]), isNull);
    });
  });

  group('DeviceTilt.fromGravity', () {
    test('lying flat, face up, is level', () {
      final tilt = DeviceTilt.fromGravity(const Gravity(0, 0, g));
      expect(tilt.pitch, closeTo(0, 1e-9));
      expect(tilt.roll, closeTo(0, 1e-9));
      expect(tilt.degrees, closeTo(0, 1e-9));
      expect(tilt.isFlat, isTrue);
    });

    test('a raised top edge is positive pitch', () {
      final a = rad(20);
      final tilt = DeviceTilt.fromGravity(
        Gravity(0, g * math.sin(a), g * math.cos(a)),
      );
      expect(tilt.pitch, closeTo(a, 1e-9));
      expect(tilt.roll, closeTo(0, 1e-9));
      expect(tilt.degrees, closeTo(20, 1e-9));
      expect(tilt.isFlat, isFalse);
    });

    test('a raised right edge is positive roll', () {
      final a = rad(10);
      final tilt = DeviceTilt.fromGravity(
        Gravity(g * math.sin(a), 0, g * math.cos(a)),
      );
      expect(tilt.roll, closeTo(a, 1e-9));
      expect(tilt.degrees, closeTo(10, 1e-9));
    });

    test('upright is 90 and face down is 180', () {
      expect(DeviceTilt.fromGravity(const Gravity(0, g, 0)).degrees, 90);
      expect(
        DeviceTilt.fromGravity(const Gravity(0, 0, -g)).degrees,
        closeTo(180, 1e-9),
      );
    });

    test('free fall reads as flat rather than nonsense', () {
      final tilt = DeviceTilt.fromGravity(const Gravity(0, 0, 0));
      expect(tilt.degrees, 0);
    });

    test('a few degrees off is still flat', () {
      final a = rad(kFlatTolerance - 1);
      final tilt = DeviceTilt.fromGravity(
        Gravity(0, g * math.sin(a), g * math.cos(a)),
      );
      expect(tilt.isFlat, isTrue);
    });
  });

  group('bubble', () {
    test('sits in the middle when flat', () {
      final b = DeviceTilt.flat.bubble;
      expect(b.dx, 0);
      expect(b.dy, closeTo(0, 1e-12));
    });

    test('rises to the high side', () {
      final top = DeviceTilt(pitch: rad(10), roll: 0, degrees: 10).bubble;
      expect(top.dy, lessThan(0)); // up, in screen coordinates
      final right = DeviceTilt(pitch: 0, roll: rad(10), degrees: 10).bubble;
      expect(right.dx, greaterThan(0));
    });

    test('never leaves its ring', () {
      final b = DeviceTilt(pitch: rad(80), roll: rad(80), degrees: 88).bubble;
      expect(math.sqrt(b.dx * b.dx + b.dy * b.dy), closeTo(1, 1e-9));
    });
  });

  test('smoothTowards moves part of the way', () {
    const from = DeviceTilt(pitch: 0, roll: 0, degrees: 0);
    const to = DeviceTilt(pitch: 1, roll: -1, degrees: 40);
    final mid = from.smoothTowards(to, 0.25);
    expect(mid.pitch, 0.25);
    expect(mid.roll, -0.25);
    expect(mid.degrees, 10);
  });
}
