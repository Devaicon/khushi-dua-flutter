/// Small charts for the overview, drawn with the panel's own colours so they
/// follow light and dark mode. Every chart names its values in text beside
/// it (a legend or labels), so nothing is read from colour alone.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/theme.dart';
import 'ui.dart';

/// One part of a [DonutChart].
class ChartSlice {
  const ChartSlice(this.label, this.value, this.color, {this.onTap});
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;
}

/// A ring split into [slices], with a headline in the middle and a legend of
/// counts and shares beside it.
///
/// With [track] set, the ring's unfilled part is drawn in that colour, for a
/// single share of a whole ("members of all users").
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.total,
    this.size = 148,
  });

  final List<ChartSlice> slices;
  final String centerValue;
  final String centerLabel;

  /// What the ring adds up to; the sum of [slices] when null. Larger than
  /// that sum, the rest of the ring is left as a faint track.
  final int? total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sum = slices.fold<int>(0, (n, s) => n + s.value);
    final whole = math.max(total ?? sum, 1);
    final ring = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(
          values: [for (final s in slices) s.value / whole],
          colors: [for (final s in slices) s.color],
          track: Palette.raised,
          gap: Palette.card,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerValue,
                  style: TextStyle(
                      color: Palette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(centerLabel, style: AdminText.muted),
            ],
          ),
        ),
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in slices)
          Tooltip(
            message: '${s.label}: ${formatCount(s.value)} '
                '(${_percent(s.value, whole)})',
            child: InkWell(
              borderRadius: Radii.smAll,
              onTap: s.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminText.body),
                    ),
                    const SizedBox(width: Space.sm),
                    Text(formatCount(s.value),
                        style: TextStyle(
                            color: Palette.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    SizedBox(
                      width: 44,
                      child: Text(_percent(s.value, whole),
                          textAlign: TextAlign.right, style: AdminText.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < size + 200
          ? Column(children: [ring, const SizedBox(height: Space.lg), legend])
          : Row(children: [
              ring,
              const SizedBox(width: Space.xl),
              Expanded(child: legend),
            ]),
    );
  }

  static String _percent(int value, int whole) =>
      '${(value * 100 / whole).round()}%';
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
    required this.gap,
  });

  /// Shares of the whole ring, 0–1.
  final List<double> values;
  final List<Color> colors;
  final Color track;
  final Color gap;

  static const double _thickness = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - _thickness / 2,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = track);

    final parts = [
      for (var i = 0; i < values.length; i++)
        if (values[i] > 0) i
    ];
    var start = -math.pi / 2;
    for (final i in parts) {
      final sweep = values[i] * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, stroke..color = colors[i]);
      start += sweep;
    }
    // A thin cut of the card's colour between parts, so neighbours never
    // touch.
    if (parts.length > 1 || (parts.length == 1 && values[parts.first] < 1)) {
      final cut = Paint()
        ..color = gap
        ..strokeWidth = 2.5;
      final center = rect.center;
      final inner = rect.width / 2 - _thickness / 2 - 1;
      final outer = rect.width / 2 + _thickness / 2 + 1;
      var at = -math.pi / 2;
      for (final i in [...parts, -1]) {
        final dir = Offset(math.cos(at), math.sin(at));
        canvas.drawLine(center + dir * inner, center + dir * outer, cut);
        if (i == -1) break;
        at += values[i] * math.pi * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values.toString() != values.toString() ||
      old.colors.toString() != colors.toString() ||
      old.track != track ||
      old.gap != gap;
}

/// One bar of a [BarList] or [ColumnChart].
class ChartBar {
  const ChartBar(this.label, this.value, {this.tooltip, this.onTap});
  final String label;
  final int value;
  final String? tooltip;
  final VoidCallback? onTap;
}

/// Labelled horizontal bars, longest first as given, with each value in
/// text at the end of its bar.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.bars, this.color, this.unit = ''});

  final List<ChartBar> bars;
  final Color? color;

  /// After each value: " duas".
  final String unit;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Palette.brandFill;
    final most = bars.fold<int>(1, (m, b) => math.max(m, b.value));
    return Column(
      children: [
        for (final b in bars)
          Tooltip(
            message: b.tooltip ?? '${b.label}: ${formatCount(b.value)}$unit',
            child: InkWell(
              borderRadius: Radii.smAll,
              onTap: b.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 128,
                      child: Text(b.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminText.body),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final width = box.maxWidth * b.value / most;
                          return Row(
                            children: [
                              Container(
                                width:
                                    math.max(width - 48, b.value == 0 ? 0 : 4),
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: Space.sm),
                              Text(formatCount(b.value),
                                  style: TextStyle(
                                      color: Palette.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Vertical bars over time, oldest on the left, with the tallest value
/// marked on a faint line and only some dates labelled.
class ColumnChart extends StatelessWidget {
  const ColumnChart({
    super.key,
    required this.bars,
    this.color,
    this.height = 150,
    this.labelEvery = 1,
  });

  final List<ChartBar> bars;
  final Color? color;
  final double height;

  /// Label one date in this many, so they never crowd.
  final int labelEvery;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Palette.brandFill;
    final most = bars.fold<int>(0, (m, b) => math.max(m, b.value));
    final scale = math.max(most, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            children: [
              // The top line, labelled with the busiest day's count.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Row(
                  children: [
                    Text('$most',
                        style: AdminText.muted.copyWith(fontSize: 11)),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Divider(height: 1, color: Palette.line)),
                  ],
                ),
              ),
              Positioned.fill(
                top: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final b in bars)
                      Expanded(
                        child: Tooltip(
                          message: b.tooltip ?? '${b.label}: ${b.value}',
                          child: InkWell(
                            onTap: b.onTap,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              // A hit target as tall as the chart, however
                              // short the bar.
                              alignment: Alignment.bottomCenter,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: FractionallySizedBox(
                                heightFactor: b.value == 0
                                    ? 0.02
                                    : math.max(b.value / scale, 0.04),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: b.value == 0 ? Palette.line : color,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Palette.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: Space.xs),
        SizedBox(
          height: 16,
          child: Row(
            children: [
              for (var i = 0; i < bars.length; i++)
                Expanded(
                  // Counted back from the newest, so it is always labelled.
                  child: OverflowBox(
                    maxWidth: 80,
                    child: Text(
                      (bars.length - 1 - i) % labelEvery == 0
                          ? bars[i].label
                          : '',
                      maxLines: 1,
                      softWrap: false,
                      style: AdminText.muted.copyWith(fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
