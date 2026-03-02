import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:prayers_times/prayers_times.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

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
  double qiblaDirection = 0; // Qibla direction from true north
  StreamSubscription<CompassEvent>? _compassSubscription; // Compass stream

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
      return;
    }

    _compassSubscription = compassEvents.listen(
      (event) {
        if (event.heading != null) {
          setState(() {
            deviceHeading = event.heading;
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
    while (angle > 180) {
      angle -= 360;
    }
    while (angle < -180) {
      angle += 360;
    }

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
                  child: const Icon(Icons.close, color: Colors.black),
                ),
              ).marginSymmetric(horizontal: 20).marginOnly(top: 12),

              const SizedBox(height: 16),

              // Kaaba icon similar to design
              Image.asset("assets/images/kaaba.png", height: 140),

              const Spacer(),

              // Compass dial section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating compass background (dial)
                  Transform.rotate(
                    angle: -(deviceHeading ?? 0) * math.pi / 180,
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF222743), // deep navy like design
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

                          // Cardinal directions styled per design
                          Positioned(
                            top: 24,
                            child: Text(
                              "N",
                              style: _textStyle(Colors.redAccent),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            child: Text("S", style: _textStyle(Colors.white)),
                          ),
                          Positioned(
                            left: 24,
                            child: Text("W", style: _textStyle(Colors.white)),
                          ),
                          Positioned(
                            right: 24,
                            child: Text("E", style: _textStyle(Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Orange Qibla needle (fixed color like design)
                  Transform.rotate(
                    angle: _getQiblaNeedleAngle() * math.pi / 180,
                    child: const Icon(
                      Icons.navigation,
                      size: 110,
                      color: Color(0xFFFFB300), // warm orange
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom Qibla text, centered like design
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    // Match design: only show `Qibla: xxx°` at bottom
    return 'Qibla: ${qiblaDirection.toStringAsFixed(0)}°';
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color);
  }
}
