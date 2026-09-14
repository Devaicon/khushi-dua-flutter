import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:prayers_times/prayers_times.dart';

import '../helpers/compassQuality.dart';
import '../helpers/qiblaMath.dart';
import '../services/declinationService.dart';

/// How long to wait for a first compass reading before telling the user their
/// device does not appear to be delivering one.
const Duration _kCompassTimeout = Duration(seconds: 6);

class CompassScreen extends StatefulWidget {
  final double latitude, longitude;
  const CompassScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  /// Qibla bearing, in degrees clockwise from **true** north.
  double _qiblaDirection = 0;

  /// Declination, sensor inventory and model validity for this device/location.
  CompassEnvironment? _env;
  bool _envResolved = false;

  /// iOS only populates `CLHeading.trueHeading` while location updates are
  /// running. `flutter_compass` never starts them, so we hold a subscription
  /// open for the lifetime of this screen.
  StreamSubscription<Position>? _positionSub;

  /// Fires if no compass event ever arrives — a device with no usable
  /// magnetometer produces an eternally empty stream rather than an error.
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _sawReading = false;

  bool _isError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    debugPrint(
      "🧭 QiblaScreen: initState - Latitude: ${widget.latitude}, Longitude: ${widget.longitude}",
    );
    _fetchQiblaDirection();
    _resolveEnvironment();
    _keepTrueHeadingAlive();
    _timeoutTimer = Timer(_kCompassTimeout, () {
      if (mounted && !_sawReading) setState(() => _timedOut = true);
    });
  }

  void _fetchQiblaDirection() {
    try {
      Coordinates coordinates = Coordinates(widget.latitude, widget.longitude);
      double calculatedQibla = Qibla.qibla(coordinates);
      debugPrint(
        "🧭 QiblaScreen: Calculated Qibla direction (true north): ${calculatedQibla.toStringAsFixed(2)}°",
      );

      if (mounted) {
        setState(() {
          _qiblaDirection = calculatedQibla;
        });
      }
    } catch (e) {
      debugPrint('❌ QiblaScreen: Error calculating Qibla direction: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMsg =
              "Ensure location permissions are granted to calculate Qibla.";
        });
      }
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
    _positionSub = Geolocator.getPositionStream(
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

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _positionSub?.cancel();
    debugPrint('🧭 QiblaScreen: disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("assets/images/qiblaBg.png"),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    debugPrint("🧭 QiblaScreen: Back button pressed");
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back();
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.black),
                ),
              ).marginSymmetric(horizontal: 20).marginOnly(top: 12),

              const SizedBox(height: 16),

              Image.asset("assets/images/kaaba.png", height: 140),

              const Spacer(),

              _buildCompassContent(),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(bottom: 28.0),
                child: Column(
                  children: [
                    Text(
                      'Qibla: ${_qiblaDirection.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_modelLine != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _modelLine!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _panel(String message,
      {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _notice(String message, {required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 28, right: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 11.5, height: 1.35),
              textAlign: TextAlign.left,
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
  List<Widget> _notices(double? accuracy) {
    final CompassEnvironment? env = _env;
    if (env == null) return const <Widget>[];

    final List<Widget> notices = <Widget>[];

    if (env.isBlackoutZone) {
      notices.add(_notice(
        'You are close to the magnetic pole, where Earth\'s horizontal field is '
        'too weak for any magnetic compass to be reliable.',
        icon: Icons.public_off,
        color: Colors.redAccent,
      ));
    } else if (env.isCautionZone) {
      notices.add(_notice(
        'Near the magnetic pole the horizontal field is weak, so compass '
        'accuracy is reduced at this location.',
        icon: Icons.public,
        color: Colors.orangeAccent,
      ));
    }

    final String? hardware = CompassQualityMessage.forQuality(env.quality);
    if (hardware != null) {
      notices.add(_notice(
        hardware,
        icon: Icons.sensors_off,
        color: Colors.orangeAccent,
      ));
    }

    // Android maps its sensor status to 45/30/15 degrees, and null when unknown.
    if (accuracy == null || accuracy > 30) {
      notices.add(_notice(
        'Low compass accuracy. Move your phone in a figure-8 to calibrate.',
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
      ));
    }

    if (!env.modelIsCurrent) {
      notices.add(_notice(
        'The bundled ${env.modelName} magnetic model is past its validity '
        'period. Update the app for the latest correction.',
        icon: Icons.update,
        color: Colors.orangeAccent,
      ));
    }

    return notices;
  }

  Widget _buildCompassContent() {
    if (_isError) {
      return _panel(_errorMsg,
          icon: Icons.error_outline, color: Colors.redAccent);
    }

    // Wait for the model and sensor inventory so the needle is never drawn
    // against a heading that has not yet been corrected to true north.
    if (!_envResolved) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // A device with no magnetometer physically cannot produce a heading.
    if (!CompassQualityMessage.canShowHeading(_env!.quality)) {
      return _panel(
        CompassQualityMessage.forQuality(_env!.quality)!,
        icon: Icons.explore_off,
        color: Colors.orangeAccent,
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _panel('Error reading compass sensor.',
              icon: Icons.explore_off, color: Colors.redAccent);
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          if (_timedOut) {
            return _panel(
              'No compass reading from this device. Check that location is '
              'enabled, or use the Qibla angle below with a separate compass.',
              icon: Icons.explore_off,
              color: Colors.orangeAccent,
            );
          }
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        final double? rawHeading = snapshot.data?.heading;

        // Android reports azimuth in [-180, 180], so negative headings are
        // ordinary there; only iOS uses a negative value (-1) to mean "true
        // north unavailable". A null or non-finite heading is unusable on
        // either platform. These previously fell through a `?? 0.0` and
        // silently rendered a needle pointing at north.
        if (!QiblaMath.isHeadingUsable(
          rawHeading,
          negativeMeansUnavailable: Platform.isIOS,
        )) {
          return _panel(
            'This device cannot provide a compass heading right now. Check that '
            'location is enabled, or use the Qibla angle below with a separate '
            'compass.',
            icon: Icons.explore_off,
            color: Colors.orangeAccent,
          );
        }

        if (!_sawReading) {
          _sawReading = true;
          _timeoutTimer?.cancel();
          debugPrint(
            '🧭 QiblaScreen: first reading rawHeading=$rawHeading '
            'accuracy=${snapshot.data?.accuracy}',
          );
        }

        // Android reports a MAGNETIC heading; iOS reports a TRUE heading and
        // resolves declination to 0. Adding declination puts both on true north,
        // which is the reference the Qibla bearing already uses.
        final double heading =
            QiblaMath.magneticToTrue(rawHeading!, _env!.declination);

        final double dialAngleRad = -QiblaMath.toRadians(heading);
        final double needleAngle =
            QiblaMath.needleAngle(_qiblaDirection, heading);
        final double needleAngleRad = QiblaMath.toRadians(needleAngle);
        final bool isPointingToQibla = QiblaMath.isAligned(needleAngle);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: dialAngleRad,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF222743),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 360; i += 30)
                          Transform.rotate(
                            angle: i * math.pi / 180,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: i % 90 == 0 ? 16 : 10,
                                width: 2,
                                color: i % 90 == 0
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                margin: const EdgeInsets.only(top: 18),
                              ),
                            ),
                          ),
                        Positioned(
                            top: 24,
                            child:
                                Text("N", style: _textStyle(Colors.redAccent))),
                        Positioned(
                            bottom: 24,
                            child: Text("S", style: _textStyle(Colors.white))),
                        Positioned(
                            left: 24,
                            child: Text("W", style: _textStyle(Colors.white))),
                        Positioned(
                            right: 24,
                            child: Text("E", style: _textStyle(Colors.white))),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: needleAngleRad,
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter:
                          QiblaNeedlePainter(color: const Color(0xFFFFB300)),
                    ),
                  ),
                ),
                if (isPointingToQibla)
                  Container(
                    height: 320,
                    width: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFFFB300), width: 3),
                    ),
                  ),
              ],
            ),
            ..._notices(snapshot.data?.accuracy),
          ],
        );
      },
    );
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color);
  }
}

class QiblaNeedlePainter extends CustomPainter {
  final Color color;

  QiblaNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    // 1. Center Top (Pointy Tip pointing exactly UP)
    path.moveTo(size.width / 2, 0);
    // 2. Bottom Right
    path.lineTo(size.width * 0.8, size.height * 0.9);
    // 3. Bottom Center Notch
    path.lineTo(size.width / 2, size.height * 0.65);
    // 4. Bottom Left
    path.lineTo(size.width * 0.2, size.height * 0.9);
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
