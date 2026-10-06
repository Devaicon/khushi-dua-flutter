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
    // Also with a cached fix, which may be from before a journey.
    _locate();
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

    // The last known fix shows a compass at once; a fresh one follows.
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('🧭 QiblaTab: last known position failed: $e');
    }
    if (position != null && mounted) {
      setState(() {
        _loading = false;
        _position = _cached = position;
      });
    }

    final fresh = await _freshPosition();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (fresh != null && _movedEnough(_position, fresh)) {
        _position = _cached = fresh;
      } else if (_position == null) {
        _problem = _LocationProblem.failed;
      }
    });
  }

  Future<Position?> _freshPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('🧭 QiblaTab: fresh position failed: $e');
      return null;
    }
  }

  /// The last known fix can be from another city after a journey; within a
  /// few kilometres the bearing does not change, so the compass is only
  /// rebuilt for a real move.
  bool _movedEnough(Position? from, Position to) {
    if (from == null) return true;
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) >
        5000;
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
        // A new position starts a new compass with the new bearing.
        key: ValueKey('${position.latitude},${position.longitude}'),
        latitude: position.latitude,
        longitude: position.longitude,
        embedded: true,
      );
    }
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: Center(
        child: _loading || _problem == null
            ? CircularProgressIndicator(color: rbluedark)
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
            style: TextStyle(
              color: rbluedark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: brandFill,
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
