import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:prayers_times/prayers_times.dart';
import 'dart:async';

import '../constants/colors.dart';

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
  double? deviceHeading; // Device's current heading (magnetic north)
  double? headingAccuracy; // Reserved for future use if plugin exposes it
  double qiblaDirection = 0; // Qibla direction from true north
  StreamSubscription<CompassEvent>? _compassSubscription; // Compass stream
  bool _compassAvailable = true;
  bool _hasLowAccuracy = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      "🧭 QiblaScreen: initState - Latitude: ${widget.latitude}, Longitude: ${widget.longitude}",
    );
    _fetchQiblaDirection();

    // Start compass after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToCompass();
    });
  }

  void _fetchQiblaDirection() {
    try {
      // Fetch Qibla direction using the Prayer Times library
      Coordinates coordinates = Coordinates(widget.latitude, widget.longitude);
      // Bearing from true north to Qibla
      double calculatedQibla = Qibla.qibla(coordinates);
      debugPrint(
        "🧭 QiblaScreen: Calculated Qibla direction: ${calculatedQibla.toStringAsFixed(2)}°",
      );
      setState(() {
        qiblaDirection = calculatedQibla;
      });
    } catch (e) {
      debugPrint('❌ QiblaScreen: Error calculating Qibla direction: $e');
    }
  }

  void _listenToCompass() {
    debugPrint("🧭 QiblaScreen: Starting compass listener...");
    final compassEvents = FlutterCompass.events;

    if (compassEvents == null) {
      debugPrint("❌ QiblaScreen: Compass not available on this device");
      setState(() {
        _compassAvailable = false;
      });
      return;
    }

    _compassSubscription = compassEvents.listen(
      (event) {
        if (event.heading != null) {
          setState(() {
            deviceHeading = event.heading;
            // Current flutter_compass does not expose accuracy on all platforms
            headingAccuracy = null;
            _hasLowAccuracy = false;
            _compassAvailable = true;
          });

          // Log occasionally to avoid spam
          if ((event.heading!.toInt()) % 45 == 0) {
            debugPrint(
              "🧭 QiblaScreen: Heading ${event.heading!.toStringAsFixed(1)}°",
            );
          }
        }
      },
      onError: (error) {
        debugPrint("❌ QiblaScreen: Compass error: $error");
        setState(() {
          _compassAvailable = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _compassSubscription?.cancel(); // Cancel the subscription to prevent errors
    debugPrint('🧭 QiblaScreen: disposed');
    super.dispose();
  }

  // Angle the Qibla needle must rotate relative to device heading
  double _getQiblaNeedleAngle() {
    if (deviceHeading == null) return 0;

    double angle = qiblaDirection - deviceHeading!; // difference in degrees

    // Normalize to -180..180 so we always take the shortest path
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;

    return angle;
  }

  bool _isPointingToQibla() {
    if (deviceHeading == null) return false;
    return _getQiblaNeedleAngle().abs() < 5; // within 5° treated as aligned
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
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close, color: rblack),
                  ),
                ),
              ).marginSymmetric(horizontal: 20).marginOnly(top: 12),

              Image.asset("assets/images/kaaba.png", height: 120),

              if (_hasLowAccuracy)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Move your device in a figure-8 pattern to calibrate compass",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isPointingToQibla())
                          Container(
                            height: 320,
                            width: 320,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                        Transform.rotate(
                          angle: -(deviceHeading ?? 0) * math.pi / 180,
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.7),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
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
                                        height: i % 90 == 0 ? 15 : 10,
                                        width: i % 90 == 0 ? 3 : 2,
                                        color: i % 90 == 0
                                            ? Colors.white
                                            : Colors.grey.withOpacity(0.5),
                                        margin: const EdgeInsets.only(top: 10),
                                      ),
                                    ),
                                  ),

                                Positioned(
                                  top: 20,
                                  child: Text(
                                    "N",
                                    style: _textStyle(Colors.red),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  child: Text(
                                    "S",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                                Positioned(
                                  left: 20,
                                  child: Text(
                                    "W",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                                Positioned(
                                  right: 20,
                                  child: Text(
                                    "E",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Transform.rotate(
                          angle: _getQiblaNeedleAngle() * math.pi / 180,
                          child: Icon(
                            Icons.navigation,
                            size: 100,
                            color: _isPointingToQibla()
                                ? Colors.green
                                : Colors.orange,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getStatusText(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!_compassAvailable)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'Compass requires a physical device with sensors.\nCannot test on iOS Simulator.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_isPointingToQibla())
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Aligned with Qibla',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    if (deviceHeading != null) {
      final diff = _getQiblaNeedleAngle().abs();
      return 'Qibla: ${qiblaDirection.toStringAsFixed(0)}°\n'
          'Current: ${deviceHeading!.toStringAsFixed(0)}°\n'
          'Off by: ${diff.toStringAsFixed(1)}°';
    } else if (!_compassAvailable) {
      return 'Qibla Direction: ${qiblaDirection.toStringAsFixed(0)}°\n(Compass not available)';
    } else {
      return 'Qibla Direction: ${qiblaDirection.toStringAsFixed(0)}°\nInitializing compass...';
    }
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: color,
      shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
    );
  }
}
