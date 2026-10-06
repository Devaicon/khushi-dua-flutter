import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../constants/theme.dart';
import 'qiblaDirection.dart';

/// The Qibla compass as a dashboard tab.
///
/// It used to open only from the prayer screen, which handed it the position
/// it had already found. As a tab it finds its own: the last known position
/// first, so the compass appears at once, then a fresh fix if there is none.
class QiblaTab extends StatefulWidget {
  const QiblaTab({super.key});

  @override
  State<QiblaTab> createState() => _QiblaTabState();
}

enum _LocationProblem { servicesOff, denied, deniedForever, failed }

class _QiblaTabState extends State<QiblaTab> {
  /// Kept across visits: the tab is rebuilt each time it is shown, so the
  /// compass sensors are not running while another tab is open.
  static Position? _cached;

  Position? _position = _cached;
  _LocationProblem? _problem;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_position == null) _locate();
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _problem = null;
    });

    final problem = await _checkAccess();
    if (problem != null) {
      if (mounted) {
        setState(() {
          _problem = problem;
          _loading = false;
        });
      }
      return;
    }

    Position? position;
    try {
      position =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          );
    } catch (e) {
      debugPrint('🧭 QiblaTab: locating failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (position == null) {
        _problem = _LocationProblem.failed;
      } else {
        _position = _cached = position;
      }
    });
  }

  Future<_LocationProblem?> _checkAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _LocationProblem.servicesOff;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return _LocationProblem.deniedForever;
      }
      if (permission == LocationPermission.denied) {
        return _LocationProblem.denied;
      }
      return null;
    } catch (e) {
      debugPrint('🧭 QiblaTab: permission check failed: $e');
      return _LocationProblem.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position != null) {
      return CompassScreen(
        latitude: position.latitude,
        longitude: position.longitude,
        embedded: true,
      );
    }
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: Center(
        child: _loading || _problem == null
            ? const CircularProgressIndicator(color: rbluedark)
            : _buildProblem(_problem!),
      ),
    );
  }

  Widget _buildProblem(_LocationProblem problem) {
    final (message, action, onAction) = switch (problem) {
      _LocationProblem.servicesOff => (
        "Turn on location to find the Qibla direction".tr,
        "Open location settings".tr,
        () async {
          await Geolocator.openLocationSettings();
        },
      ),
      _LocationProblem.deniedForever => (
        "Allow location access in settings to find the Qibla direction".tr,
        "Open app settings".tr,
        () async {
          await Geolocator.openAppSettings();
        },
      ),
      _LocationProblem.denied || _LocationProblem.failed => (
        "Your location is needed to find the Qibla direction".tr,
        "Try again".tr,
        _locate,
      ),
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: rbluedark.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_off_rounded,
              size: 48,
              color: rbluedark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: rbluedark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: rbluedark,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
            ),
            child: Text(action),
          ),
          // Coming back from the settings app does not rebuild this tab.
          if (problem != _LocationProblem.denied &&
              problem != _LocationProblem.failed)
            TextButton(
              onPressed: _locate,
              style: TextButton.styleFrom(foregroundColor: rbluedark),
              child: Text("Try again".tr),
            ),
        ],
      ),
    );
  }
}
