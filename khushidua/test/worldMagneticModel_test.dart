import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/worldMagneticModel.dart';

void main() {
  final WorldMagneticModel wmm = WorldMagneticModel.wmm2025();

  group('model metadata', () {
    test('is the current WMM epoch', () {
      expect(wmm.model, 'WMM-2025');
      expect(wmm.epoch, 2025.0);
      expect(wmm.expiry, 2030.0);
    });

    test('validity window covers the epoch but not its end', () {
      expect(wmm.isValidFor(2025.0), isTrue);
      expect(wmm.isValidFor(2029.99), isTrue);
      expect(wmm.isValidFor(2030.0), isFalse);
      expect(wmm.isValidFor(2024.99), isFalse);
    });
  });

  group('declination matches the NOAA reference implementation', () {
    // Reference values generated with pygeomag 1.1.0 using NOAA's official
    // WMM_2025.COF, across a global grid plus named cities. See
    // test/wmm_reference.json.
    final List<dynamic> reference = jsonDecode(
      File('test/wmm_reference.json').readAsStringSync(),
    ) as List<dynamic>;

    test('reference dataset is present and non-trivial', () {
      expect(reference.length, greaterThan(300));
    });

    test('every reference point agrees within 1e-6 degrees', () {
      double worst = 0;
      String worstAt = '';

      for (final dynamic entry in reference) {
        final Map<String, dynamic> row = entry as Map<String, dynamic>;
        final double lat = (row['lat'] as num).toDouble();
        final double lon = (row['lon'] as num).toDouble();
        final double alt = (row['alt'] as num).toDouble();
        final double time = (row['time'] as num).toDouble();
        final double expected = (row['decl'] as num).toDouble();

        final double actual = wmm
            .calculate(
              latitude: lat,
              longitude: lon,
              altitudeKm: alt,
              decimalYear: time,
            )
            .declination;

        final double error = (actual - expected).abs();
        if (error > worst) {
          worst = error;
          worstAt = '${row['name'] ?? ''} lat=$lat lon=$lon t=$time '
              'expected=$expected actual=$actual';
        }
      }

      expect(worst, lessThan(1e-6), reason: 'worst mismatch at $worstAt');
    });
  });

  group('named locations', () {
    // Sanity anchors so a regression is legible without diffing the grid.
    void expectDeclination(String name, double lat, double lon, double expected) {
      test(name, () {
        final double d = wmm
            .calculate(latitude: lat, longitude: lon, decimalYear: 2026.7)
            .declination;
        expect(d, closeTo(expected, 0.01));
      });
    }

    expectDeclination('Lahore is slightly east', 31.5497, 74.3436, 2.198);
    expectDeclination('London is slightly east', 51.5074, -0.1278, 1.196);
    expectDeclination('New York is strongly west', 40.7128, -74.0060, -12.466);
    expectDeclination('Seattle is strongly east', 47.6062, -122.3321, 14.880);
    expectDeclination('Auckland is strongly east', -36.8485, 174.7633, 20.330);
    expectDeclination('Cape Town is strongly west', -33.9249, 18.4241, -26.787);
  });

  group('polar reliability zones', () {
    test('mid-latitudes are neither blackout nor caution', () {
      final GeomagneticField f =
          wmm.calculate(latitude: 31.5497, longitude: 74.3436, decimalYear: 2026.7);
      expect(f.isBlackoutZone, isFalse);
      expect(f.isCautionZone, isFalse);
      expect(f.horizontalIntensity, greaterThan(6000));
    });

    test('the north magnetic pole region is a blackout zone', () {
      // The north magnetic pole sits in the Arctic Ocean; H collapses there.
      final GeomagneticField f =
          wmm.calculate(latitude: 86.0, longitude: 150.0, decimalYear: 2026.7);
      expect(f.horizontalIntensity, lessThan(2000));
      expect(f.isBlackoutZone, isTrue);
    });
  });

  group('geographic poles do not blow up', () {
    test('north pole returns a finite declination', () {
      final GeomagneticField f =
          wmm.calculate(latitude: 90.0, longitude: 0.0, decimalYear: 2026.7);
      expect(f.declination.isFinite, isTrue);
      expect(f.horizontalIntensity.isFinite, isTrue);
    });

    test('south pole returns a finite declination', () {
      final GeomagneticField f =
          wmm.calculate(latitude: -90.0, longitude: 0.0, decimalYear: 2026.7);
      expect(f.declination.isFinite, isTrue);
    });
  });

  group('decimalYear', () {
    test('start of year is the year itself', () {
      expect(WorldMagneticModel.decimalYear(DateTime.utc(2026)),
          closeTo(2026.0, 1e-9));
    });

    test('mid-year is about .5', () {
      expect(WorldMagneticModel.decimalYear(DateTime.utc(2026, 7, 2)),
          closeTo(2026.5, 0.01));
    });
  });

  group('repeated evaluation is stateless', () {
    test('same input gives the same answer after other queries', () {
      final double first = wmm
          .calculate(latitude: 31.5497, longitude: 74.3436, decimalYear: 2026.7)
          .declination;
      wmm.calculate(latitude: -80, longitude: 179, decimalYear: 2029.0);
      wmm.calculate(latitude: 12, longitude: -33, decimalYear: 2025.1);
      final double second = wmm
          .calculate(latitude: 31.5497, longitude: 74.3436, decimalYear: 2026.7)
          .declination;
      expect(second, equals(first));
    });
  });
}
