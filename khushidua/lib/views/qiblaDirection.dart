import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:prayers_times/prayers_times.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import '../helpers/compassQuality.dart';
import '../helpers/compassTilt.dart';
import '../helpers/qiblaMath.dart';
import '../services/compassCues.dart';
import '../services/declinationService.dart';
import '../services/headingService.dart';

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

/// Share of each gravity reading blended into the dial's tilt.
const double _kTiltSmoothing = 0.35;

/// Perspective of the leaning dial: larger is more dramatic.
const double _kPerspective = 0.0015;

/// How thick the dial is, and in how many slices its edge is drawn: one per
/// pixel, so the edge reads as solid when the dial leans.
const double _kDialThickness = 12;
const int _kDialEdgeSlices = 12;

/// The buzz on reaching the Qibla comes at most this often, so a phone held
/// at the edge of the tolerance does not keep buzzing.
const Duration _kAlignedCueGap = Duration(seconds: 3);

/// How long the compass takes to fade in when it first appears.
const Duration _kAppearDuration = Duration(milliseconds: 250);

/// How long a notice's toast stays before it folds into the header button.
const Duration _kToastDuration = Duration(seconds: 4);

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

class _CompassScreenState extends State<CompassScreen>
    with WidgetsBindingObserver {
  /// Qibla bearing, in degrees clockwise from **true** north.
  double _qiblaDirection = 0;

  /// Declination, field strength, sensor inventory and model validity for
  /// this device and location.
  CompassEnvironment? _env;
  bool _envResolved = false;

  /// iOS only populates `CLHeading.trueHeading` while location updates are
  /// running. `flutter_compass` never starts them, so we hold a subscription
  /// open while the screen is in use.
  StreamSubscription<Position>? _positionSub;

  StreamSubscription<HeadingReading?>? _headingSub;
  StreamSubscription<Gravity>? _gravitySub;

  /// How the phone is held, smoothed; leans the dial and moves the level.
  DeviceTilt _tilt = DeviceTilt.flat;
  bool _sawTilt = false;

  /// Held well off flat for long enough to suggest holding it flatter.
  final SustainedFlag _tilted = SustainedFlag(
    dwell: const Duration(seconds: 3),
  );

  /// Fires if no heading ever arrives — a device with no usable magnetometer
  /// can produce an eternally empty stream rather than an error.
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _sawReading = false;

  /// The smoothed heading, in degrees clockwise from **true** north.
  double? _heading;

  /// The latest reading, for its source and accuracy.
  HeadingReading? _reading;
  bool _headingUnusable = false;
  bool _sensorError = false;

  /// Poor accuracy, and a field unlike Earth's, each held long enough to be
  /// worth a notice under the compass. Both clear quickly, so the notice goes
  /// as soon as the problem has.
  final SustainedFlag _needsCalibration = SustainedFlag(
    dwell: const Duration(seconds: 3),
    clearDwell: const Duration(seconds: 1),
  );
  final SustainedFlag _interference = SustainedFlag(
    dwell: const Duration(seconds: 3),
    clearDwell: const Duration(seconds: 1),
  );

  bool _aligned = false;
  DateTime? _lastAlignedCue;

  /// The notice toasting under the header, if any. Each kind toasts once per
  /// run of the app, however often the tab is opened; after that it waits
  /// behind the header button.
  _CompassNotice? _toast;
  Timer? _toastTimer;
  static final Set<String> _toasted = <String>{};

  bool _isError = false;
  String _errorMsg = '';

  DateTime? _lastDiagnostic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchQiblaDirection();
    _resolveEnvironment();
    _startSensors();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The sensors, and on iOS location updates, cost battery and nothing
    // reads them while the app is out of sight.
    switch (state) {
      case AppLifecycleState.resumed:
        if (_headingSub == null) _startSensors();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopSensors();
      case AppLifecycleState.inactive:
        break;
    }
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
      _syncToast();
    }
  }

  void _startSensors() {
    _keepTrueHeadingAlive();
    _headingSub = HeadingService.events().listen(
      _onReading,
      onError: (Object e) {
        debugPrint('🧭 QiblaScreen: heading error - $e');
        if (mounted) setState(() => _sensorError = true);
      },
    );
    _gravitySub = HeadingService.gravity().listen(
      _onGravity,
      onError: (Object e) => debugPrint('🧭 QiblaScreen: tilt error - $e'),
    );
    if (!_sawReading) {
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(_kCompassTimeout, () {
        if (mounted && !_sawReading) setState(() => _timedOut = true);
      });
    }
  }

  void _stopSensors() {
    _timeoutTimer?.cancel();
    _headingSub?.cancel();
    _headingSub = null;
    _gravitySub?.cancel();
    _gravitySub = null;
    _positionSub?.cancel();
    _positionSub = null;
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

  void _onReading(HeadingReading? reading) {
    if (!mounted) return;
    if (reading == null) {
      setState(() => _headingUnusable = true);
      return;
    }

    if (!_sawReading) {
      _sawReading = true;
      _timeoutTimer?.cancel();
      debugPrint(
        '🧭 QiblaScreen: first reading ${reading.heading.toStringAsFixed(1)}° '
        '${reading.reference.name} from ${reading.source.name}',
      );
    }

    // A magnetic heading means nothing for the Qibla until the declination
    // is known, which takes a moment after the screen opens.
    final CompassEnvironment? env = _env;
    final bool magnetic = reading.reference == HeadingReference.magneticNorth;
    if (magnetic && env == null) return;

    // The Qibla bearing is from true north, so the heading must be too.
    final double heading = magnetic
        ? QiblaMath.magneticToTrue(reading.heading, env!.declination)
        : reading.heading;
    final double? previous = _heading;
    final double smoothed = previous == null
        ? heading
        : QiblaMath.smoothAngle(previous, heading, _kSmoothing);

    final DateTime now = DateTime.now();
    final bool aligned = _isAlignedFor(smoothed);
    // One short buzz on arriving at the Qibla, so the phone can be turned
    // without watching the screen.
    final DateTime? lastCue = _lastAlignedCue;
    if (aligned &&
        !_aligned &&
        (lastCue == null || now.difference(lastCue) >= _kAlignedCueGap)) {
      _lastAlignedCue = now;
      CompassCues.aligned();
    }

    final bool? poor = isPoorHeading(
      errorDegrees: reading.errorDegrees,
      magnetometerStatus: reading.magnetometerStatus,
      wasPoor: _needsCalibration.value,
    );
    if (poor != null) _needsCalibration.update(poor, now);
    final double? field = reading.fieldMicroTesla;
    if (field != null && env != null) {
      final double deviation = fieldDeviation(
        measuredMicroTesla: field,
        expectedNanoTesla: env.totalIntensity,
      );
      _interference.update(
        deviation >
            (_interference.value ? kFieldDeviationClear : kFieldDeviationWarn),
        now,
      );
    }

    if (kDebugMode || reading.verbose) {
      _logDiagnostics(reading, heading, smoothed, now);
    }

    setState(() {
      _heading = smoothed;
      _reading = reading;
      _headingUnusable = false;
      _aligned = aligned;
    });
    _syncToast();
  }

  void _onGravity(Gravity gravity) {
    if (!mounted) return;
    final DeviceTilt next = DeviceTilt.fromGravity(gravity);
    final DeviceTilt tilt = _sawTilt
        ? _tilt.smoothTowards(next, _kTiltSmoothing)
        : next;
    _sawTilt = true;
    _tilted.update(tilt.degrees > kTiltWarning, DateTime.now());
    setState(() => _tilt = tilt);
    _syncToast();
  }

  /// Leans the dial as if it lay level while the phone tilts, like a card
  /// compass held in the hand. Flat when the system asks for less motion.
  ///
  /// [depth] pushes a slice of the dial's edge that far behind its face.
  Matrix4 _dialTransform(BuildContext context, {double depth = 0}) {
    if (MediaQuery.disableAnimationsOf(context)) return Matrix4.identity();
    double clamp(double a) => a.clamp(-kMaxDialTilt, kMaxDialTilt);
    // A raised edge of the phone leaves that side of the level dial lower,
    // so it leans away.
    return Matrix4.identity()
      ..setEntry(3, 2, _kPerspective)
      ..rotateX(-clamp(_tilt.pitch))
      ..rotateY(-clamp(_tilt.roll))
      ..translateByDouble(0, 0, depth, 1);
  }

  /// Once a second in debug builds, or when switched on natively: every stage from the platform's heading
  /// to the needle, to compare with the native log (tag `QiblaHeading`).
  void _logDiagnostics(
    HeadingReading reading,
    double heading,
    double smoothed,
    DateTime now,
  ) {
    final DateTime? last = _lastDiagnostic;
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return;
    }
    _lastDiagnostic = now;
    final CompassEnvironment? env = _env;
    final bool magnetic = reading.reference == HeadingReference.magneticNorth;
    String f(double? v) => v?.toStringAsFixed(1) ?? '-';
    debugPrint(
      '🧭 Qibla: ${reading.source.name} '
      'raw=${f(reading.heading)} ${reading.reference.name} '
      'decl=${magnetic ? f(env?.declination) : '0 (already true)'} '
      'true=${f(heading)} shown=${f(smoothed)} '
      '±${f(reading.errorDegrees)} status=${reading.magnetometerStatus} '
      '|B|=${f(reading.fieldMicroTesla)}uT '
      'expected=${f(env == null ? null : env.totalIntensity / 1000)}uT '
      'qibla=${f(_qiblaDirection)} '
      'needle=${f(QiblaMath.needleAngle(_qiblaDirection, smoothed))} '
      'calibrate=${_needsCalibration.value} interference=${_interference.value}',
    );
  }

  /// Aligned within [_kAlignTolerance]; once aligned, stays so until past
  /// [_kReleaseTolerance]. [heading] is from true north.
  bool _isAlignedFor(double heading) {
    final double needle = QiblaMath.needleAngle(_qiblaDirection, heading);
    return QiblaMath.isAligned(
      needle,
      tolerance: _aligned ? _kReleaseTolerance : _kAlignTolerance,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toastTimer?.cancel();
    _stopSensors();
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
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Fits any screen: the dial takes what is left after
                      // the guidance, never more than 340.
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
                  Positioned(
                    top: AppSpace.sm,
                    left: AppSpace.lg,
                    right: AppSpace.lg,
                    child: _buildToast(),
                  ),
                ],
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
        if (_showingCompass) ...[
          const SizedBox(width: AppSpace.sm),
          _buildNoticesButton(_notices().length),
        ],
      ],
    );
  }

  /// Where the heading comes from and how far the platform trusts it, so the
  /// reading is attributable rather than opaque.
  String? get _modelLine {
    final CompassEnvironment? env = _env;
    if (env == null) return null;
    final HeadingReading? reading = _reading;

    final String sign = env.declination >= 0 ? 'E' : 'W';
    final String declination =
        '${env.modelName} · declination '
        '${env.declination.abs().toStringAsFixed(1)}°$sign';
    final String frame = switch (reading?.source) {
      HeadingSource.fusedOrientation =>
        'True north via Google fused orientation',
      HeadingSource.coreLocation => 'True north via Core Location',
      HeadingSource.rotationVector || HeadingSource.accelMag => declination,
      null => Platform.isIOS ? 'True north via Core Location' : declination,
    };

    final double? error = reading?.errorDegrees;
    final String? accuracy =
        error != null &&
            error.isFinite &&
            error >= 0 &&
            error < kNoEstimateError
        ? '±${error.round()}°'
        : switch (reading?.magnetometerStatus) {
            3 => 'accuracy high',
            2 => 'accuracy medium',
            1 => 'accuracy low',
            0 => 'accuracy unreliable',
            _ => null,
          };
    return accuracy == null ? frame : '$accuracy · $frame';
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

  /// A limitation worth knowing about: a soft tint of its colour rather than
  /// a dark box. Listed in the notices sheet, and shown once as a toast.
  Widget _notice(_CompassNotice notice) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          notice.color.withValues(alpha: 0.10),
          AppSurface.card,
        ),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notice.icon, color: notice.color, size: 18),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              notice.message,
              style: TextStyle(color: rtext, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the dial is on screen, rather than a problem panel that already
  /// says what is wrong.
  bool get _showingCompass =>
      !_isError &&
      _env != null &&
      CompassQualityMessage.canShowHeading(_env!.quality) &&
      !_sensorError &&
      !_headingUnusable &&
      _heading != null;

  /// Every limitation worth telling the user about, most severe first. They
  /// live behind the header's notices button, so the compass never moves when
  /// one comes or goes.
  ///
  /// The magnetic model is applied identically on every device, so anything
  /// listed here is a limit of the hardware or the location, not of the app.
  List<_CompassNotice> _notices() {
    final CompassEnvironment? env = _env;
    if (env == null || !_showingCompass) return const <_CompassNotice>[];

    final List<_CompassNotice> notices = <_CompassNotice>[];

    if (_tilted.value) {
      notices.add(
        const _CompassNotice(
          'tilt',
          'Hold your phone flat for the most accurate direction: centre the '
              'bubble in the ring.',
          icon: Icons.phone_android,
          color: _kWarnAmber,
        ),
      );
    }

    if (env.isBlackoutZone) {
      notices.add(
        const _CompassNotice(
          'pole',
          'You are close to the magnetic pole, where Earth\'s horizontal field '
              'is too weak for any magnetic compass to be reliable.',
          icon: Icons.public_off,
          color: _kWarnRed,
        ),
      );
    } else if (env.isCautionZone) {
      notices.add(
        const _CompassNotice(
          'pole',
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
        _CompassNotice(
          'hardware',
          hardware,
          icon: Icons.sensors_off,
          color: _kWarnAmber,
        ),
      );
    }

    // One accuracy notice at most: interference says what to move away
    // from, which is also the first step of calibrating.
    if (_interference.value && _reading?.fieldMicroTesla != null) {
      notices.add(
        const _CompassNotice(
          'interference',
          'Metal, magnets or electronics nearby may be affecting the compass. '
              'Move away from them, or remove a magnetic case, for a more '
              'accurate direction.',
          icon: Icons.sensors,
          color: _kWarnAmber,
        ),
      );
    } else if (_needsCalibration.value) {
      // Only when the platform's own estimate has stayed poor, so a heading
      // that is good enough for the Qibla is never called unusable.
      notices.add(
        _CompassNotice(
          'calibration',
          "The compass needs calibrating. Move your phone in a figure-8 a few times, away from metal and magnets."
              .tr,
          icon: Icons.warning_amber_rounded,
          color: _kWarnAmber,
        ),
      );
    }

    if (!env.modelIsCurrent) {
      notices.add(
        _CompassNotice(
          'model',
          'The bundled ${env.modelName} magnetic model is past its validity '
              'period. Update the app for the latest correction.',
          icon: Icons.update,
          color: _kWarnAmber,
        ),
      );
    }

    return notices;
  }

  /// Toasts a notice the first time it appears in this run of the app, and
  /// takes the toast down early once its problem has gone.
  void _syncToast() {
    final List<_CompassNotice> notices = _notices();
    final _CompassNotice? showing = _toast;
    if (showing != null && !notices.any((n) => n.id == showing.id)) {
      _hideToast();
    }
    if (_toast != null) return;
    for (final _CompassNotice notice in notices) {
      if (_toasted.add(notice.id)) {
        _toastTimer?.cancel();
        _toastTimer = Timer(_kToastDuration, _hideToast);
        setState(() => _toast = notice);
        return;
      }
    }
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (mounted && _toast != null) setState(() => _toast = null);
  }

  /// Every current notice, or word that there are none.
  void _openNotices() {
    _hideToast();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppSurface.card,
      showDragHandle: true,
      builder: (context) {
        final List<_CompassNotice> notices = _notices();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Compass accuracy".tr,
                  style: TextStyle(
                    color: rtext,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                if (notices.isEmpty)
                  Text(
                    "Nothing is affecting the compass right now.".tr,
                    style: TextStyle(color: AppText.onPageMuted, fontSize: 14),
                  )
                else
                  for (final (i, notice) in notices.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpace.sm),
                    _notice(notice),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// The header's notices button: a warning sign, with a count while anything is
  /// affecting the compass.
  Widget _buildNoticesButton(int count) {
    return Tooltip(
      message: "Compass accuracy".tr,
      child: InkWell(
        onTap: _openNotices,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.sm + 2),
              decoration: BoxDecoration(
                color: AppSurface.card,
                shape: BoxShape.circle,
                boxShadow: AppElevation.card,
              ),
              child: Icon(
                count > 0
                    ? Icons.warning_rounded
                    : Icons.warning_amber_rounded,
                color: count > 0 ? _kWarnAmber : rbluedark,
                size: 22,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedScale(
                scale: count > 0 ? 1 : 0,
                duration: AppMotion.base,
                curve: AppMotion.curve,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kWarnAmber,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppSurface.card, width: 1.5),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A notice pinned under the header, over the compass rather than above
  /// it, so nothing moves. Tapping it opens every notice.
  Widget _buildToast() {
    final _CompassNotice? toast = _toast;
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: toast == null
          ? const SizedBox.shrink(key: ValueKey('none'))
          : GestureDetector(
              key: ValueKey(toast.id),
              onTap: _openNotices,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smAll,
                  boxShadow: AppElevation.card,
                ),
                child: _notice(toast),
              ),
            ),
    );
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
      return _withBearing(
        _panel(
          CompassQualityMessage.forQuality(_env!.quality)!,
          icon: Icons.explore_off,
          color: _kWarnAmber,
        ),
      );
    }

    if (_sensorError) {
      return _withBearing(
        _panel(
          'Error reading compass sensor. Use the Qibla angle below with a '
          'separate compass.',
          icon: Icons.explore_off,
          color: _kWarnRed,
        ),
      );
    }

    if (_headingUnusable) {
      return _withBearing(
        _panel(
          'This device cannot provide a compass heading right now. Check that '
          'location is enabled, or use the Qibla angle below with a separate '
          'compass.',
          icon: Icons.explore_off,
          color: _kWarnAmber,
        ),
      );
    }

    final double? heading = _heading;
    if (heading == null) {
      if (_timedOut) {
        return _withBearing(
          _panel(
            'No compass reading from this device. Check that location is '
            'enabled, or use the Qibla angle below with a separate compass.',
            icon: Icons.explore_off,
            color: _kWarnAmber,
          ),
        );
      }
      return CircularProgressIndicator(color: rbluedark);
    }

    // Both are from true north: see _onReading.
    final double turn = QiblaMath.signedDifference(_qiblaDirection, heading);

    // Fades in, growing slightly, when the first heading arrives. The tween
    // only ever ends at 1, so later rebuilds leave it alone.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _kAppearDuration,
      curve: AppMotion.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
      ),
      child: Column(
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The dial's edge, deepest slice first, so it reads as a
                  // solid disc rather than a slate when it leans.
                  for (int i = _kDialEdgeSlices; i >= 1; i--)
                    Transform(
                      alignment: Alignment.center,
                      transform: _dialTransform(
                        context,
                        depth: _kDialThickness * i / _kDialEdgeSlices,
                      ),
                      child: CustomPaint(
                        painter: DialEdgePainter(
                          depth: i / _kDialEdgeSlices,
                          glow: glow,
                        ),
                      ),
                    ),
                  Transform(
                    alignment: Alignment.center,
                    transform: _dialTransform(context),
                    child: CustomPaint(
                      painter: CompassPainter(
                        heading: heading,
                        qibla: _qiblaDirection,
                        glow: glow,
                      ),
                    ),
                  ),
                  // Not leaned with the dial: it shows the lean.
                  CustomPaint(
                    painter: LevelPainter(tilt: _tilt, glow: glow),
                  ),
                ],
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
          const SizedBox(height: AppSpace.lg),
        ],
      ),
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

  /// A problem panel with the bearing under it, which its text refers to.
  Widget _withBearing(Widget panel) => Column(
    children: [
      panel,
      const SizedBox(height: AppSpace.lg),
      _buildBearing(),
    ],
  );

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

/// The dial's radius in a box of [size], leaving room for the top mark and
/// the glow.
double compassDialRadius(Size size) => size.shortestSide / 2 - 18;

/// One slice of the dial's edge, [depth] of the way (0 to 1) from its face to
/// its base: darker the deeper, like the side of a solid disc in shade.
class DialEdgePainter extends CustomPainter {
  DialEdgePainter({required this.depth, required this.glow});

  final double depth;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Color side = Color.lerp(
      AppSurface.raised,
      rbluedark,
      AppPalette.isDark ? 0.15 + 0.25 * depth : 0.18 + 0.3 * depth,
    )!;
    final Offset center = size.center(Offset.zero);
    final double r = compassDialRadius(size);
    // The deepest slice carries the shadow, so it falls under the whole disc.
    if (depth == 1) {
      canvas.drawCircle(
        center + const Offset(0, 6),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Color.lerp(side, _kGoldInk, glow * 0.6)!,
    );
  }

  @override
  bool shouldRepaint(DialEdgePainter old) =>
      old.depth != depth || old.glow != glow;
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
    final double r = compassDialRadius(size);
    final Rect face = Rect.fromCircle(center: center, radius: r);

    // The gold glow when aligned, behind the face. The shadow is under the
    // dial's edge: see DialEdgePainter.
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

/// A bubble level at the centre of the compass. The bubble drifts to the
/// high side of the phone and settles in the ring, turning gold, when the
/// phone lies flat — which is when the heading is most accurate.
class LevelPainter extends CustomPainter {
  LevelPainter({required this.tilt, required this.glow});

  final DeviceTilt tilt;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double travel = size.shortestSide * 0.13;
    final Color color = tilt.isFlat ? _kGold : rbluedark;

    canvas.drawCircle(
      center,
      19,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: tilt.isFlat ? 0.9 : 0.35),
    );

    final ({double dx, double dy}) b = tilt.bubble;
    final Offset at = center + Offset(b.dx, b.dy) * travel;
    canvas.drawCircle(
      at,
      12,
      Paint()..color = Color.lerp(color, _kGold, glow)!.withValues(alpha: 0.55),
    );
    // A highlight, so it reads as a bubble.
    canvas.drawCircle(
      at + const Offset(-3.8, -3.8),
      3.2,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(LevelPainter old) =>
      old.tilt.pitch != tilt.pitch ||
      old.tilt.roll != tilt.roll ||
      old.tilt.degrees != tilt.degrees ||
      old.glow != glow;
}

/// Something limiting the compass, for the header's notices button.
class _CompassNotice {
  const _CompassNotice(
    this.id,
    this.message, {
    required this.icon,
    required this.color,
  });

  /// Which kind of notice this is, so each kind toasts only once.
  final String id;
  final String message;
  final IconData icon;
  final Color color;
}
