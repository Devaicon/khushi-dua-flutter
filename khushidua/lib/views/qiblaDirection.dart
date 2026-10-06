import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:prayers_times/prayers_times.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../helpers/compassQuality.dart';
import '../helpers/qiblaMath.dart';
import '../services/declinationService.dart';

/// How long to wait for a first compass reading before telling the user their
/// device does not appear to be delivering one.
const Duration _kCompassTimeout = Duration(seconds: 6);

/// The needle counts as on the Qibla within this many degrees, and only lets
/// go past [_kReleaseTolerance], so it does not flicker on the boundary.
const double _kAlignTolerance = 5;
const double _kReleaseTolerance = 8;

/// Share of each new reading blended into the shown heading (~30 readings a
/// second): steady enough to read, quick enough to follow a turn.
const double _kSmoothing = 0.2;

const Color _kGold = Color(0xFFFFB300);

/// The gold, deep enough for text on the light page.
const Color _kGoldInk = Color(0xFFB7791F);
const Color _kNorth = Color(0xFFE53935);
const Color _kWarnAmber = Color(0xFFE08A00);
const Color _kWarnRed = Color(0xFFE53935);

class CompassScreen extends StatefulWidget {
  final double latitude, longitude;

  /// True when shown as a dashboard tab, where there is nothing to close.
  final bool embedded;

  const CompassScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.embedded = false,
  });

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  static const EventChannel _accuracyChannel = EventChannel(
    'com.khushiidua.app/compassAccuracy',
  );

  /// Qibla bearing, in degrees clockwise from **true** north.
  double _qiblaDirection = 0;

  /// Declination, sensor inventory and model validity for this device/location.
  CompassEnvironment? _env;
  bool _envResolved = false;

  /// iOS only populates `CLHeading.trueHeading` while location updates are
  /// running. `flutter_compass` never starts them, so we hold a subscription
  /// open for the lifetime of this screen.
  StreamSubscription<Position>? _positionSub;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<dynamic>? _accuracySub;

  /// Fires if no compass event ever arrives — a device with no usable
  /// magnetometer produces an eternally empty stream rather than an error.
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _sawReading = false;

  /// The smoothed raw platform heading (magnetic on Android, true on iOS).
  double? _rawHeading;
  bool _headingUnusable = false;
  bool _sensorError = false;

  /// Android: the magnetometer's SensorManager status. iOS: heading accuracy
  /// in degrees, from flutter_compass.
  int? _magnetometerStatus;
  double? _iosAccuracy;

  bool _aligned = false;

  bool _isError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchQiblaDirection();
    _resolveEnvironment();
    _keepTrueHeadingAlive();
    _listenToCompass();
    _timeoutTimer = Timer(_kCompassTimeout, () {
      if (mounted && !_sawReading) setState(() => _timedOut = true);
    });
  }

  void _fetchQiblaDirection() {
    try {
      _qiblaDirection = Qibla.qibla(
        Coordinates(widget.latitude, widget.longitude),
      );
      debugPrint(
        '🧭 QiblaScreen: (${widget.latitude}, ${widget.longitude}) '
        'qibla=${_qiblaDirection.toStringAsFixed(2)}° true',
      );
    } catch (e) {
      debugPrint('❌ QiblaScreen: Error calculating Qibla direction: $e');
      _isError = true;
      _errorMsg = "Ensure location permissions are granted to calculate Qibla.";
    }
  }

  Future<void> _resolveEnvironment() async {
    final CompassEnvironment env = await DeclinationService.resolve(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (mounted) {
      setState(() {
        _env = env;
        _envResolved = true;
      });
    }
  }

  /// Keeps iOS location updates flowing so `trueHeading` stays valid.
  void _keepTrueHeadingAlive() {
    if (!Platform.isIOS) return;
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen(
          (_) {},
          onError: (Object e) =>
              debugPrint('🧭 QiblaScreen: position stream error - $e'),
        );
  }

  void _listenToCompass() {
    _compassSub = FlutterCompass.events?.listen(
      _onCompassEvent,
      onError: (Object e) {
        debugPrint('🧭 QiblaScreen: compass error - $e');
        if (mounted) setState(() => _sensorError = true);
      },
    );
    if (Platform.isAndroid) {
      _accuracySub = _accuracyChannel.receiveBroadcastStream().listen(
        (status) {
          if (status is int && mounted) {
            setState(() => _magnetometerStatus = status);
          }
        },
        onError: (Object e) =>
            debugPrint('🧭 QiblaScreen: accuracy stream error - $e'),
      );
    }
  }

  void _onCompassEvent(CompassEvent event) {
    final double? raw = event.heading;
    // Android reports azimuth in [-180, 180], so negative headings are
    // ordinary there; only iOS uses a negative value (-1) to mean "true north
    // unavailable". A null or non-finite heading is unusable on either.
    if (!QiblaMath.isHeadingUsable(
      raw,
      negativeMeansUnavailable: Platform.isIOS,
    )) {
      if (mounted) setState(() => _headingUnusable = true);
      return;
    }

    if (!_sawReading) {
      _sawReading = true;
      _timeoutTimer?.cancel();
      debugPrint(
        '🧭 QiblaScreen: first reading raw=$raw accuracy=${event.accuracy}',
      );
    }

    final double reading = QiblaMath.normalize(raw!);
    final double smoothed = _rawHeading == null
        ? reading
        : QiblaMath.smoothAngle(_rawHeading!, reading, _kSmoothing);

    final bool aligned = _isAlignedFor(smoothed);
    // One short buzz on arriving at the Qibla, so the phone can be turned
    // without watching the screen.
    if (aligned && !_aligned) HapticFeedback.mediumImpact();

    if (!mounted) return;
    setState(() {
      _rawHeading = smoothed;
      _headingUnusable = false;
      _iosAccuracy = event.accuracy;
      _aligned = aligned;
    });
  }

  /// Aligned within [_kAlignTolerance]; once aligned, stays so until past
  /// [_kReleaseTolerance].
  bool _isAlignedFor(double rawHeading) {
    final env = _env;
    if (env == null) return false;
    final double needle = QiblaMath.needleAngle(
      _qiblaDirection,
      QiblaMath.magneticToTrue(rawHeading, env.declination),
    );
    return QiblaMath.isAligned(
      needle,
      tolerance: _aligned ? _kReleaseTolerance : _kAlignTolerance,
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _compassSub?.cancel();
    _accuracySub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The light page every other tab uses; the old photo background made
    // this the one screen that looked like a different app.
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: SafeArea(
        // As a tab, the dashboard already keeps clear of the status bar.
        top: !widget.embedded,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                0,
              ),
              child: _buildHeader(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Fits any screen: the dial takes what is left after the
                  // guidance and notices, never more than 340.
                  final double size = math.min(
                    math.min(constraints.maxWidth - 40, 340),
                    constraints.maxHeight * 0.64,
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_buildCompassContent(size)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Title and the bearing, in the same place and style as the other tabs'
  /// headers.
  Widget _buildHeader() {
    return Row(
      children: [
        if (!widget.embedded) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: rbluedark,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Qibla Direction".tr,
                style: TextStyle(
                  color: rtext,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isError
                    ? ''
                    : '${"Qibla".tr}: ${_qiblaDirection.toStringAsFixed(0)}°',
                style: TextStyle(color: AppText.onPageMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows which magnetic model produced the correction, so the reading is
  /// attributable rather than opaque.
  String? get _modelLine {
    final CompassEnvironment? env = _env;
    if (env == null) return null;
    if (DeclinationService.platformReportsTrueNorth) {
      return 'True north via Core Location';
    }
    final String sign = env.declination >= 0 ? 'E' : 'W';
    return '${env.modelName} · declination '
        '${env.declination.abs().toStringAsFixed(1)}°$sign';
  }

  /// A problem that stops the compass: a white card, like the location
  /// problems on the Qibla tab.
  Widget _panel(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: plainCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            message,
            style: TextStyle(color: rtext, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// A limitation worth knowing about, under the compass: a soft tint of its
  /// colour rather than a dark box.
  Widget _notice(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        top: AppSpace.sm,
        left: AppSpace.lg,
        right: AppSpace.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: rtext, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  /// Every limitation worth telling the user about, most severe first.
  ///
  /// The magnetic model is applied identically on every device, so anything
  /// listed here is a limit of the hardware or the location, not of the app.
  List<Widget> _notices() {
    final CompassEnvironment? env = _env;
    if (env == null) return const <Widget>[];

    final List<Widget> notices = <Widget>[];

    if (env.isBlackoutZone) {
      notices.add(
        _notice(
          'You are close to the magnetic pole, where Earth\'s horizontal field is '
          'too weak for any magnetic compass to be reliable.',
          icon: Icons.public_off,
          color: _kWarnRed,
        ),
      );
    } else if (env.isCautionZone) {
      notices.add(
        _notice(
          'Near the magnetic pole the horizontal field is weak, so compass '
          'accuracy is reduced at this location.',
          icon: Icons.public,
          color: _kWarnAmber,
        ),
      );
    }

    final String? hardware = CompassQualityMessage.forQuality(env.quality);
    if (hardware != null) {
      notices.add(
        _notice(hardware, icon: Icons.sensors_off, color: _kWarnAmber),
      );
    }

    if (needsCalibration(
      isAndroid: Platform.isAndroid,
      magnetometerStatus: _magnetometerStatus,
      iosAccuracyDegrees: _iosAccuracy,
    )) {
      notices.add(
        _notice(
          "The compass needs calibrating. Move your phone in a figure-8 a few times, away from metal and magnets."
              .tr,
          icon: Icons.warning_amber_rounded,
          color: _kWarnAmber,
        ),
      );
    }

    if (!env.modelIsCurrent) {
      notices.add(
        _notice(
          'The bundled ${env.modelName} magnetic model is past its validity '
          'period. Update the app for the latest correction.',
          icon: Icons.update,
          color: _kWarnAmber,
        ),
      );
    }

    return notices;
  }

  Widget _buildCompassContent(double size) {
    if (_isError) {
      return _panel(_errorMsg, icon: Icons.error_outline, color: _kWarnRed);
    }

    // Wait for the model and sensor inventory so the needle is never drawn
    // against a heading that has not yet been corrected to true north.
    if (!_envResolved) {
      return CircularProgressIndicator(color: rbluedark);
    }

    // A device with no magnetometer physically cannot produce a heading.
    if (!CompassQualityMessage.canShowHeading(_env!.quality)) {
      return Column(
        children: [
          _panel(
            CompassQualityMessage.forQuality(_env!.quality)!,
            icon: Icons.explore_off,
            color: _kWarnAmber,
          ),
          const SizedBox(height: AppSpace.lg),
          _buildBearing(),
        ],
      );
    }

    if (_sensorError) {
      return _panel(
        'Error reading compass sensor.',
        icon: Icons.explore_off,
        color: _kWarnRed,
      );
    }

    if (_headingUnusable) {
      return _panel(
        'This device cannot provide a compass heading right now. Check that '
        'location is enabled, or use the Qibla angle below with a separate '
        'compass.',
        icon: Icons.explore_off,
        color: _kWarnAmber,
      );
    }

    final double? raw = _rawHeading;
    if (raw == null) {
      if (_timedOut) {
        return _panel(
          'No compass reading from this device. Check that location is '
          'enabled, or use the Qibla angle below with a separate compass.',
          icon: Icons.explore_off,
          color: _kWarnAmber,
        );
      }
      return CircularProgressIndicator(color: rbluedark);
    }

    // Android reports a MAGNETIC heading; iOS reports a TRUE heading and
    // resolves declination to 0. Adding declination puts both on true north,
    // which is the reference the Qibla bearing already uses.
    final double heading = QiblaMath.magneticToTrue(raw, _env!.declination);
    final double turn = QiblaMath.signedDifference(_qiblaDirection, heading);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed size whatever the state: alignment changes colour only, so
        // nothing on the screen moves when the phone comes onto the Qibla.
        TweenAnimationBuilder<double>(
          tween: Tween(end: _aligned ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, glow, _) => SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: CompassPainter(
                heading: heading,
                qibla: _qiblaDirection,
                glow: glow,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _buildGuidance(turn),
        if (_modelLine != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            _modelLine!,
            style: TextStyle(fontSize: 11, color: AppText.onPageMuted),
          ),
        ],
        ..._notices(),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }

  /// "Facing the Qibla", or which way to turn and how far.
  Widget _buildGuidance(double turn) {
    final Widget content;
    if (_aligned) {
      content = Row(
        key: const ValueKey('aligned'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: _kGoldInk, size: 24),
          const SizedBox(width: AppSpace.sm),
          Text(
            "Facing the Qibla".tr,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _kGoldInk,
            ),
          ),
        ],
      );
    } else {
      final degrees = turn.abs().round().toString();
      content = Row(
        key: const ValueKey('turn'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            turn > 0 ? Icons.turn_right_rounded : Icons.turn_left_rounded,
            color: rbluedark,
            size: 24,
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            turn > 0
                ? "Turn right @degrees°".trParams({'degrees': degrees})
                : "Turn left @degrees°".trParams({'degrees': degrees}),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: rbluedark,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(duration: AppMotion.base, child: content);
  }

  /// The bearing on its own, for a phone with no compass to point with.
  Widget _buildBearing() {
    return Column(
      children: [
        Text(
          '${"Qibla".tr}: ${_qiblaDirection.toStringAsFixed(0)}°',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: rbluedark,
          ),
        ),
        if (_modelLine != null) ...[
          const SizedBox(height: 2),
          Text(
            _modelLine!,
            style: TextStyle(fontSize: 11, color: AppText.onPageMuted),
          ),
        ],
      ],
    );
  }
}

/// The whole compass in one paint: a white dial that turns with the phone,
/// the Qibla marked on its rim, a needle with a dotted line out to it, and a
/// fixed mark at the top for where the phone points.
///
/// [glow] runs from 0 to 1 as the phone comes onto the Qibla and fades the
/// rim, needle, line and marks to gold — without changing any size.
class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.heading,
    required this.qibla,
    required this.glow,
  });

  /// Which way the phone points, degrees clockwise from true north.
  final double heading;

  /// The Qibla bearing, degrees clockwise from true north.
  final double qibla;

  final double glow;

  Color _gold(Color from) => Color.lerp(from, _kGold, glow)!;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    // Leaves room for the top mark and the glow inside the box.
    final double r = size.shortestSide / 2 - 18;
    final Rect face = Rect.fromCircle(center: center, radius: r);

    // Soft shadow, then the gold glow when aligned, both behind the face.
    canvas.drawCircle(
      center + const Offset(0, 6),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    if (glow > 0) {
      canvas.drawCircle(
        center,
        r + 2,
        Paint()
          ..color = _kGold.withValues(alpha: 0.4 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [AppSurface.card, AppSurface.raised],
          stops: [0.62, 1],
        ).createShader(face),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + 1.5 * glow
        ..color = _gold(rbluedark.withValues(alpha: 0.08)),
    );

    // Where the phone points: a fixed mark above the dial. It is no bigger
    // than the Kaaba badge, which covers it exactly when aligned.
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - r - 2)
        ..lineTo(center.dx - 7, center.dy - r - 13)
        ..lineTo(center.dx + 7, center.dy - r - 13)
        ..close(),
      Paint()..color = _gold(rbluedark),
    );

    // Dial: rotated so north on the dial points at real north.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-QiblaMath.toRadians(heading));
    _paintDial(canvas, r);
    canvas.restore();

    // Needle: points at the Qibla relative to the top of the phone.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(QiblaMath.toRadians(QiblaMath.needleAngle(qibla, heading)));
    _paintNeedle(canvas, r);
    canvas.restore();
  }

  void _paintDial(Canvas canvas, double r) {
    final Paint tick = Paint()..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 5) {
      final bool cardinal = deg % 90 == 0;
      final bool major = deg % 30 == 0;
      final double length = cardinal ? 14 : (major ? 10 : 5);
      tick
        ..strokeWidth = cardinal ? 2.5 : (major ? 1.8 : 1)
        ..color = deg == 0
            ? _kNorth
            : rbluedark.withValues(
                alpha: cardinal ? 0.8 : (major ? 0.45 : 0.18),
              );
      final double a = QiblaMath.toRadians(deg.toDouble());
      final Offset dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(dir * (r - 8), dir * (r - 8 - length), tick);
    }

    // Labels sit inside the tick ring, clear of it.
    const Map<int, String> cardinals = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    for (int deg = 0; deg < 360; deg += 30) {
      final String? letter = cardinals[deg];
      _paintLabel(
        canvas,
        letter ?? '$deg',
        angle: deg.toDouble(),
        radius: r - (letter != null ? 40 : 34),
        style: TextStyle(
          color: deg == 0
              ? _kNorth
              : rbluedark.withValues(alpha: letter != null ? 0.9 : 0.4),
          fontSize: letter != null ? 18 : 10,
          fontWeight: letter != null ? FontWeight.bold : FontWeight.w600,
        ),
      );
    }

    // A hairline inner ring, for depth.
    canvas.drawCircle(
      Offset.zero,
      r - 58,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rbluedark.withValues(alpha: 0.06),
    );

    // The Qibla's place on the dial: a small Kaaba in a badge on the rim.
    final double q = QiblaMath.toRadians(qibla);
    final Offset at = Offset(math.sin(q), -math.cos(q)) * r;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.drawCircle(
      const Offset(0, 2),
      14,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset.zero, 14, Paint()..color = _gold(AppSurface.card));
    canvas.rotate(q);
    final Rect kaaba = Rect.fromCenter(
      center: Offset.zero,
      width: 13,
      height: 13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaaba, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF1B1B1F),
    );
    canvas.drawRect(
      Rect.fromLTWH(kaaba.left, kaaba.top + 3, kaaba.width, 2.2),
      Paint()..color = const Color(0xFFE0A100),
    );
    canvas.restore();
  }

  void _paintLabel(
    Canvas canvas,
    String text, {
    required double angle,
    required double radius,
    required TextStyle style,
  }) {
    final double a = QiblaMath.toRadians(angle);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(math.sin(a) * radius, -math.cos(a) * radius);
    // Upright relative to the dial's edge, like a real compass card.
    canvas.rotate(a);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _paintNeedle(Canvas canvas, double r) {
    final double length = r * 0.42;

    // Dotted line from the needle's tip to the Kaaba on the rim.
    final Paint dots = Paint()
      ..color = _gold(rbluedark.withValues(alpha: 0.28))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (double y = length + 10; y < r - 18; y += 9) {
      canvas.drawLine(Offset(0, -y), Offset(0, -y - 1.5), dots);
    }

    final Path needle = Path()
      ..moveTo(0, -length)
      ..lineTo(length * 0.26, length * 0.34)
      ..lineTo(0, length * 0.16)
      ..lineTo(-length * 0.26, length * 0.34)
      ..close();
    canvas.drawShadow(needle, Colors.black, 3, false);
    canvas.drawPath(
      needle,
      Paint()
        ..color = _gold(
          AppPalette.isDark ? const Color(0xFF7986CB) : const Color(0xFF3949AB),
        ),
    );
    // A darker half gives the needle some depth.
    canvas.drawPath(
      Path()
        ..moveTo(0, -length)
        ..lineTo(length * 0.26, length * 0.34)
        ..lineTo(0, length * 0.16)
        ..close(),
      Paint()..color = Color.lerp(rbluedark, const Color(0xFFE69500), glow)!,
    );
    canvas.drawCircle(Offset.zero, 7, Paint()..color = AppSurface.card);
    canvas.drawCircle(
      Offset.zero,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _gold(rbluedark),
    );
  }

  @override
  bool shouldRepaint(CompassPainter old) =>
      old.heading != heading || old.qibla != qibla || old.glow != glow;
}
