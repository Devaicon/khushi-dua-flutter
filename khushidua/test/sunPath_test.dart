import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/sunPath.dart';

void main() {
  final sunrise = DateTime(2026, 10, 6, 7, 0);
  final sunset = DateTime(2026, 10, 6, 18, 30);

  ({double x, bool isDay}) at(int h, int m) => SunPath.positionAt(
    now: DateTime(2026, 10, 6, h, m),
    sunrise: sunrise,
    sunset: sunset,
  );

  test('the sun sits on the horizon at sunrise and sunset', () {
    expect(at(7, 0).x, closeTo(SunPath.riseX, 1e-9));
    expect(at(18, 30).x, closeTo(SunPath.setX, 1e-9));
    expect(SunPath.heightAt(SunPath.riseX), closeTo(0, 1e-9));
    expect(SunPath.heightAt(SunPath.setX), closeTo(0, 1e-9));
  });

  test('midway through the day it is at the top of the hill', () {
    final noon = at(12, 45);
    expect(noon.isDay, isTrue);
    expect(noon.x, closeTo(0.5, 1e-9));
    expect(SunPath.heightAt(noon.x), closeTo(1, 1e-9));
  });

  test('at night it is below the horizon, deepest at midnight', () {
    final early = at(3, 0);
    final late = at(22, 0);
    expect(early.isDay, isFalse);
    expect(late.isDay, isFalse);
    expect(early.x, lessThan(SunPath.riseX));
    expect(late.x, greaterThan(SunPath.setX));
    expect(SunPath.heightAt(early.x), lessThan(0));
    expect(SunPath.heightAt(0), closeTo(-SunPath.nightDepth, 1e-9));
    expect(SunPath.heightAt(1), closeTo(-SunPath.nightDepth, 1e-9));
  });

  test('moves left to right through the day', () {
    final xs = [
      at(1, 0),
      at(7, 30),
      at(12, 0),
      at(17, 0),
      at(23, 0),
    ].map((p) => p.x).toList();
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }
  });
}
