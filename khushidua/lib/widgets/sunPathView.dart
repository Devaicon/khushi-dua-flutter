import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../constants/theme.dart';
import '../helpers/sunPath.dart';

const Color _kSun = Color(0xFFFFC107);

/// The sun's place in today's sky, for the next-prayer card: a hill from
/// sunrise to sunset with the sun on it, and the two times beneath.
///
/// Drawn for a dark surface (the card's navy).
class SunPathView extends StatelessWidget {
  const SunPathView({
    super.key,
    required this.now,
    required this.sunrise,
    required this.sunset,
    this.showTimes = true,
    this.height = 64,
  });

  final DateTime now;
  final DateTime sunrise;
  final DateTime sunset;

  /// Off for the small preview on the settings screen.
  final bool showTimes;
  final double height;

  @override
  Widget build(BuildContext context) {
    final position = SunPath.positionAt(
      now: now,
      sunrise: sunrise,
      sunset: sunset,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: SunPathPainter(x: position.x, isDay: position.isDay),
          ),
        ),
        if (showTimes) ...[
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              _time("Sunrise".tr, sunrise, CrossAxisAlignment.start),
              const Spacer(),
              _time("Sunset".tr, sunset, CrossAxisAlignment.end),
            ],
          ),
        ],
      ],
    );
  }

  Widget _time(String label, DateTime at, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          DateFormat('h:mm a').format(at),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppText.onSurfaceMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class SunPathPainter extends CustomPainter {
  SunPathPainter({required this.x, required this.isDay});

  /// The sun's place across the path, 0–1.
  final double x;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size size) {
    // Room for the sun's glow above the hill and the dip below the horizon.
    const double sunRadius = 7;
    final double top = sunRadius + 4;
    final double hill = (size.height - top) / (1 + SunPath.nightDepth);
    final double horizon = top + hill;

    Offset point(double px) =>
        Offset(px * size.width, horizon - SunPath.heightAt(px) * hill);

    Path pathBetween(double from, double to) {
      final path = Path()..moveTo(point(from).dx, point(from).dy);
      const steps = 80;
      for (int i = 1; i <= steps; i++) {
        final p = point(from + (to - from) * i / steps);
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    // Horizon.
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1,
    );

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Night either side, faint; the hill brighter.
    canvas.drawPath(
      pathBetween(0, SunPath.riseX),
      line..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      pathBetween(SunPath.setX, 1),
      line..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      pathBetween(SunPath.riseX, SunPath.setX),
      line..color = Colors.white.withValues(alpha: 0.32),
    );

    // The part of the day already gone: a warm fill under the hill and the
    // line traced in gold, up to the sun.
    final double travelled = isDay
        ? x
        : (x > SunPath.setX ? SunPath.setX : SunPath.riseX);
    if (travelled > SunPath.riseX) {
      final Path fill = pathBetween(SunPath.riseX, travelled)
        ..lineTo(travelled * size.width, horizon)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kSun.withValues(alpha: 0.35),
              _kSun.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTRB(0, top, size.width, horizon)),
      );
      canvas.drawPath(
        pathBetween(SunPath.riseX, travelled),
        line..color = _kSun,
      );
    }

    // Sunrise and sunset marks on the horizon.
    for (final px in [SunPath.riseX, SunPath.setX]) {
      canvas.drawCircle(
        Offset(px * size.width, horizon),
        3,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    final Offset sun = point(x);
    if (isDay) {
      canvas.drawCircle(
        sun,
        sunRadius * 2.2,
        Paint()
          ..color = _kSun.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(sun, sunRadius, Paint()..color = _kSun);
    } else {
      // Below the horizon: a crescent moon, cut out of a disc so it works
      // on any background.
      final Rect bounds = Rect.fromCircle(center: sun, radius: sunRadius + 2);
      canvas.saveLayer(bounds, Paint());
      canvas.drawCircle(
        sun,
        sunRadius - 1,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        sun + const Offset(sunRadius * 0.45, -sunRadius * 0.35),
        sunRadius - 1,
        Paint()..blendMode = BlendMode.dstOut,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SunPathPainter old) => old.x != x || old.isDay != isDay;
}
