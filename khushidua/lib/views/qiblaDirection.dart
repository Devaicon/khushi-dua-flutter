import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:prayers_times/prayers_times.dart';

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
  // Qibla direction from true north
  double _qiblaDirection = 0;

  // Error state
  bool _isError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    debugPrint(
      "🧭 QiblaScreen: initState - Latitude: ${widget.latitude}, Longitude: ${widget.longitude}",
    );
    _fetchQiblaDirection();
  }

  void _fetchQiblaDirection() {
    try {
      Coordinates coordinates = Coordinates(widget.latitude, widget.longitude);
      double calculatedQibla = Qibla.qibla(coordinates);
      debugPrint("🧭 QiblaScreen: Calculated Qibla direction: ${calculatedQibla.toStringAsFixed(2)}°");
      
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
          _errorMsg = "Ensure location permissions are granted to calculate Qibla.";
        });
      }
    }
  }

  @override
  void dispose() {
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

              // Top Kaaba icon
              Image.asset("assets/images/kaaba.png", height: 140),

              const Spacer(),

              // Core compass builder handling states gracefully
              _buildCompassContent(),

              const SizedBox(height: 24),

              // Bottom Qibla text showing degrees
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

  Widget _buildCompassContent() {
    if (_isError) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 12),
            Text(
              _errorMsg,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Main Compass view
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error reading compass sensor.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        double rawHeading = snapshot.data?.heading ?? 0.0;
        
        // Exact normalisation logic as advised by the client
        double heading = rawHeading % 360;
        if (heading < 0) heading += 360;

        // Dial rotates opposite to heading
        double dialAngleRad = -1 * heading * math.pi / 180;

        // Needle formula explicitly required by client: (qibla - heading + 360) % 360
        double needleAngle = (_qiblaDirection - heading + 360) % 360;
        double needleAngleRad = needleAngle * math.pi / 180;

        bool isPointingToQibla = needleAngle < 5 || needleAngle > 355; // Grace tolerance

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Rotating Dial
            Transform.rotate(
              angle: dialAngleRad,
              child: Container(
                height: 300,
                width: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF222743), // Deep Navy background
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

                    // Map Markers correctly positioned statically
                    Positioned(top: 24, child: Text("N", style: _textStyle(Colors.redAccent))),
                    Positioned(bottom: 24, child: Text("S", style: _textStyle(Colors.white))),
                    Positioned(left: 24, child: Text("W", style: _textStyle(Colors.white))),
                    Positioned(right: 24, child: Text("E", style: _textStyle(Colors.white))),
                  ],
                ),
              ),
            ),

            // Independent Needle Rotation for Qibla using CustomPainter
            Transform.rotate(
              angle: needleAngleRad,
              child: SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: QiblaNeedlePainter(color: const Color(0xFFFFB300)), // Warm orange
                ),
              ),
            ),

            // Optional Glow when Perfectly Aligned (Within a margin scale factor)
            if (isPointingToQibla)
              Container(
                height: 320,
                width: 320,
                decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: const Color(0xFFFFB300), width: 3),
                ),
              ),
          ],
        );
      }
    );
  }

  String _getStatusText() {
    return 'Qibla: ${_qiblaDirection.toStringAsFixed(0)}°';
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

    // Adds a tiny bit of shadow underneath the needle
    canvas.drawShadow(path, Colors.black, 4.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
