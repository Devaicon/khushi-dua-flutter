import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:prayers_times/prayers_times.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

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
  double? deviceHeading; // Device's current heading
  double qiblaDirection = 0; // Qibla direction
  StreamSubscription<CompassEvent>? _compassSubscription; // Compass stream

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request location permission for compass
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _fetchQiblaDirection();
      _listenToCompass();
    } else {
      Get.snackbar(
        'Permission Required',
        'Location permission is needed for Qibla direction',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _fetchQiblaDirection() {
    // Fetch Qibla direction using the Prayer Times library
    Coordinates coordinates = Coordinates(widget.latitude, widget.longitude);
    setState(() {
      qiblaDirection = Qibla.qibla(coordinates);
    });
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (event.heading != null) {
          setState(() {
            deviceHeading = event.heading;
          });
        }
      },
      onError: (error) {
        debugPrint('Compass error: $error');
        // Show message that compass requires physical device
        Get.snackbar(
          'Compass Unavailable',
          'Compass requires a physical device. This feature may not work on iOS simulator.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      },
    );
  }

  @override
  void dispose() {
    _compassSubscription?.cancel(); // Cancel the subscription to prevent errors
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
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
                    Get.back();
                  },
                  child: Icon(Icons.close, color: rblack),
                ),
              ).marginSymmetric(horizontal: 20).marginOnly(top: 12),
              Image.asset("assets/images/kaaba.png"),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating Compass Background (Dial)
                        Transform.rotate(
                          angle:
                              -((deviceHeading ?? 0) *
                                  math.pi /
                                  180), // Rotate dial based on heading
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Compass Markings
                                for (var i = 0; i < 360; i += 30)
                                  Transform.rotate(
                                    angle: i * math.pi / 180,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        height: 10,
                                        width: 2,
                                        color: i % 90 == 0
                                            ? Colors.white
                                            : Colors.grey,
                                        margin: const EdgeInsets.only(top: 10),
                                      ),
                                    ),
                                  ),

                                // N, E, S, W labels
                                Positioned(
                                  top: 15,
                                  child: Text(
                                    "N",
                                    style: _textStyle(Colors.red),
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  child: Text(
                                    "S",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                                Positioned(
                                  left: 15,
                                  child: Text(
                                    "W",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                                Positioned(
                                  right: 15,
                                  child: Text(
                                    "E",
                                    style: _textStyle(Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Qibla Direction Needle (Fixed)
                        Transform.rotate(
                          angle:
                              ((qiblaDirection - (deviceHeading ?? 0)) *
                              math.pi /
                              180), // Adjusted Qibla needle
                          child: const Icon(
                            Icons.navigation,
                            size: 100,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Display Degrees
                    Text(
                      deviceHeading == null
                          ? "Waiting for compass..."
                          : "Qibla: ${qiblaDirection.toStringAsFixed(0)}°",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rwhite,
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

  TextStyle _textStyle(Color color) {
    return TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color);
  }
}
