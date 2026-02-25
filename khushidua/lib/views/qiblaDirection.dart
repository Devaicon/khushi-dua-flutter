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
  const CompassScreen({super.key, required this.latitude, required this.longitude});

  @override
  _CompassScreenState createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? deviceHeading; // Device's current heading
  double qiblaDirection = 0; // Qibla direction
  StreamSubscription<CompassEvent>? _compassSubscription; // Compass stream
  bool _permissionGranted = false;
  bool _compassAvailable = true;

  @override
  void initState() {
    super.initState();
    debugPrint("QiblaScreen: initState - Latitude: ${widget.latitude}, Longitude: ${widget.longitude}");
    _fetchQiblaDirection();
    // Delay permission request until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    debugPrint("QiblaScreen: Requesting location permission...");
    // Request location permission for compass
    var status = await Permission.locationWhenInUse.request();
    debugPrint("QiblaScreen: Permission status: $status");
    
    if (status.isGranted) {
      debugPrint("QiblaScreen: Permission granted, starting compass...");
      setState(() {
        _permissionGranted = true;
      });
      _listenToCompass();
    } else {
      debugPrint("QiblaScreen: Permission denied");
      setState(() {
        _permissionGranted = false;
      });
      if (mounted && Get.context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Permission Required',
            'Location permission is needed for compass. Showing Qibla direction only.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        });
      }
    }
  }

  void _fetchQiblaDirection() {
    // Fetch Qibla direction using the Prayer Times library
    Coordinates coordinates = Coordinates(widget.latitude, widget.longitude);
    double calculatedQibla = Qibla.qibla(coordinates);
    debugPrint("QiblaScreen: Calculated Qibla direction: $calculatedQibla°");
    setState(() {
      qiblaDirection = calculatedQibla;
    });
  }

  void _listenToCompass() {
    debugPrint("QiblaScreen: Starting compass listener...");
    final compassEvents = FlutterCompass.events;
    
    if (compassEvents == null) {
      debugPrint("QiblaScreen: Compass not available on this device");
      setState(() {
        _compassAvailable = false;
      });
      if (mounted && Get.context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Compass Unavailable',
            'Compass sensor not available. Showing Qibla direction: ${qiblaDirection.toStringAsFixed(0)}°',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        });
      }
      return;
    }
    
    _compassSubscription = compassEvents.listen(
      (event) {
        if (event.heading != null) {
          setState(() {
            deviceHeading = event.heading;
            _compassAvailable = true;
          });
          // Log occasionally to avoid spam
          if ((event.heading!.toInt()) % 45 == 0) {
            debugPrint("QiblaScreen: Device heading: ${event.heading!.toStringAsFixed(0)}°");
          }
        }
      },
      onError: (error) {
        debugPrint("QiblaScreen: Compass error: $error");
        setState(() {
          _compassAvailable = false;
        });
        // Show message that compass requires physical device
        if (mounted && Get.context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(
              'Compass Unavailable',
              'Compass requires a physical device. Showing Qibla direction: ${qiblaDirection.toStringAsFixed(0)}°',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
          });
        }
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
            image: AssetImage("assets/images/qiblaBg.png")
          )
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                      onTap: (){
                        debugPrint("QiblaScreen: Back button pressed");
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Get.back();
                        }
                      },
                      child: Icon(Icons.close,color: rblack,))).marginSymmetric(horizontal: 20).marginOnly(top: 12),
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
                          angle: -((deviceHeading ?? 0) * math.pi / 180), // Rotate dial based on heading
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
                                        color: i % 90 == 0 ? Colors.white : Colors.grey,
                                        margin: const EdgeInsets.only(top: 10),
                                      ),
                                    ),
                                  ),
                
                                // N, E, S, W labels
                                Positioned(top: 15, child: Text("N", style: _textStyle(Colors.red))),
                                Positioned(bottom: 15, child: Text("S", style: _textStyle(Colors.white))),
                                Positioned(left: 15, child: Text("W", style: _textStyle(Colors.white))),
                                Positioned(right: 15, child: Text("E", style: _textStyle(Colors.white))),
                              ],
                            ),
                          ),
                        ),
                
                        // Qibla Direction Needle (Fixed)
                        Transform.rotate(
                          angle: ((qiblaDirection - (deviceHeading ?? 0)) * math.pi / 180), // Adjusted Qibla needle
                          child: const Icon(Icons.navigation, size: 100, color: Colors.orange),
                        ),
                      ],
                    ),
                
                    const SizedBox(height: 20),
                
                    // Display Degrees
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rwhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_compassAvailable || !_permissionGranted)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _getHelpText(),
                          style: TextStyle(
                            fontSize: 14,
                            color: rwhite.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
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
      return "Qibla: ${qiblaDirection.toStringAsFixed(0)}°\nHeading: ${deviceHeading!.toStringAsFixed(0)}°";
    } else if (!_permissionGranted) {
      return "Qibla Direction: ${qiblaDirection.toStringAsFixed(0)}°\n(Permission needed for compass)";
    } else if (!_compassAvailable) {
      return "Qibla Direction: ${qiblaDirection.toStringAsFixed(0)}°\n(Compass not available)";
    } else {
      return "Qibla Direction: ${qiblaDirection.toStringAsFixed(0)}°\nInitializing compass...";
    }
  }

  String _getHelpText() {
    if (!_permissionGranted) {
      return "Grant location permission to enable compass";
    } else if (!_compassAvailable) {
      return "Compass requires a physical device with sensors";
    } else {
      return "Point your device toward Qibla direction";
    }
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color);
  }
}
