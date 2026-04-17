import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../models/namazModel.dart';
import '../qiblaDirection.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  HijriCalendar selectedHijriDate = HijriCalendar.now();
  DateTime selectedEnglishDate = DateTime.now();

  Coordinates coordinates = Coordinates(21.1959, 72.7933);

  PrayerCalculationParameters params = PrayerCalculationMethod.karachi();
  Position? currentPosition;

  bool locationAllowed = false;
  bool isLoadingPrayerTimes = true;
  String locationName = "Loading...";
  String timezoneName = "UTC"; // Default timezone

  final List<NamazModel> _namazList = [];

  // Calculation and Juristic Method state
  String selectedCalculationMethod = "karachi";
  String selectedJuristicMethod = "shafi";

  var ishaaVolume = "on";

  Timer? _timer;
  Duration _timeToNextPrayer = Duration.zero;
  String _nextPrayerName = "";
  PrayerTimes? _prayerTimes;

  @override
  void initState() {
    super.initState();
    _loadPrayerSettings();
  }

  Future<void> _loadPrayerSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCalculationMethod =
          prefs.getString("calculationMethod") ?? "karachi";
      selectedJuristicMethod = prefs.getString("juristicMethod") ?? "shafi";
    });
    _updateCalculationParams();
    setPosition();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  void _calculateNextPrayer() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    DateTime? nextTime;
    String name = "";

    final prayers = {
      "Fajr": _prayerTimes!.fajrStartTime,
      "Sunrise": _prayerTimes!.sunrise,
      "Dhuhr": _prayerTimes!.dhuhrStartTime,
      "Asr": _prayerTimes!.asrStartTime,
      "Maghrib": _prayerTimes!.maghribStartTime,
      "Ishaa": _prayerTimes!.ishaStartTime,
    };

    for (var entry in prayers.entries) {
      if (entry.value != null && entry.value!.isAfter(now)) {
        nextTime = entry.value;
        name = entry.key;
        break;
      }
    }

    // If no more prayers today, next is Fajr tomorrow
    if (nextTime == null) {
      name = "Fajr";
      // This is simplified; in a real app you'd calculate tomorrow's prayer times
      // For UI purposes, we'll just show the name if we can't get exact tomorrow time easily
    }

    if (nextTime != null) {
      setState(() {
        _timeToNextPrayer = nextTime!.difference(now);
        _nextPrayerName = name;
      });
    }
  }

  void _updateCalculationParams() {
    try {
      // Get calculation parameters based on selected method
      switch (selectedCalculationMethod) {
        case "karachi":
          params = PrayerCalculationMethod.karachi();
          break;
        case "muslimWorldLeague":
          params = PrayerCalculationMethod.muslimWorldLeague();
          break;
        case "northAmerica":
          params = PrayerCalculationMethod.northAmerica();
          break;
        case "egyptian":
          params = PrayerCalculationMethod.egyptian();
          break;
        case "singapore":
          params = PrayerCalculationMethod.singapore();
          break;
        case "ummAlQura":
          params = PrayerCalculationMethod.ummAlQura();
          break;
        default:
          params = PrayerCalculationMethod.karachi();
      }

      // Set madhab (juristic method)
      if (selectedJuristicMethod == "hanafi") {
        params.madhab = PrayerMadhab.hanafi;
      } else {
        params.madhab = PrayerMadhab.shafi;
      }
    } catch (e) {
      debugPrint('Error updating calculation params: $e');
      // Fallback to default
      params = PrayerCalculationMethod.karachi();
      params.madhab = PrayerMadhab.shafi;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationAllowed = false;
        locationName = "Location services disabled";
      });
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationAllowed = false;
          locationName = "Permission denied";
        });
        return Future.error('Location permissions are denied');
      } else {
        setState(() {
          locationAllowed = true;
        });
      }
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationAllowed = false;
        locationName = "Permission denied";
      });
      return Future.error('Location permissions are permanently denied.');
    } else {
      setState(() {
        locationAllowed = true;
      });
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationAllowed = false;
        locationName = "Permission denied";
      });
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current position
    currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return currentPosition!;
  }

  Future<void> _getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Robust city detection
        String city = place.locality ?? "";
        if (city.isEmpty) city = place.subLocality ?? "";
        if (city.isEmpty) city = place.subAdministrativeArea ?? "";
        if (city.isEmpty) city = place.name ?? "";

        String country = place.country ?? "";
        String isoCountryCode = place.isoCountryCode ?? "";

        // Determine timezone based on coordinates (simplified approach)
        if (isoCountryCode.isNotEmpty) {
          if (isoCountryCode == "PK") {
            timezoneName = "Asia/Karachi";
          } else if (isoCountryCode == "IN") {
            timezoneName = "Asia/Kolkata";
          } else if (isoCountryCode == "SA") {
            timezoneName = "Asia/Riyadh";
          } else if (isoCountryCode == "AE") {
            timezoneName = "Asia/Dubai";
          } else {
            int offsetHours = (position.longitude / 15).round();
            timezoneName = _getTimezoneFromOffset(offsetHours);
          }
        } else {
          int offsetHours = (position.longitude / 15).round();
          timezoneName = _getTimezoneFromOffset(offsetHours);
        }

        setState(() {
          if (city.isNotEmpty && country.isNotEmpty) {
            locationName = "$city, $country";
          } else if (city.isNotEmpty) {
            locationName = city;
          } else if (country.isNotEmpty) {
            locationName = country;
          } else {
            locationName = "Unknown location";
          }
        });
      } else {
        setState(() {
          locationName = "Unknown location";
        });
      }
    } catch (e) {
      debugPrint('Error getting location name: $e');
      setState(() {
        locationName = "Location Error";
      });
    }
  }

  /// Maps UTC offset hours to a valid IANA timezone name
  /// Falls back to Asia/Karachi if offset cannot be mapped
  String _getTimezoneFromOffset(int offsetHours) {
    // Common UTC offset to timezone mappings
    // This is a simplified mapping - for production, consider using a proper timezone library
    final timezoneMap = {
      -12: "Pacific/Kwajalein",
      -11: "Pacific/Midway",
      -10: "Pacific/Honolulu",
      -9: "America/Anchorage",
      -8: "America/Los_Angeles",
      -7: "America/Denver",
      -6: "America/Chicago",
      -5: "America/New_York",
      -4: "America/Halifax",
      -3: "America/Sao_Paulo",
      -2: "Atlantic/South_Georgia",
      -1: "Atlantic/Azores",
      0: "Europe/London",
      1: "Europe/Paris",
      2: "Europe/Cairo",
      3: "Asia/Baghdad",
      4: "Asia/Dubai",
      5: "Asia/Karachi",
      5.5: "Asia/Kolkata",
      6: "Asia/Dhaka",
      7: "Asia/Bangkok",
      8: "Asia/Shanghai",
      9: "Asia/Tokyo",
      10: "Australia/Sydney",
      11: "Pacific/Norfolk",
      12: "Pacific/Auckland",
    };

    // Try exact match first
    if (timezoneMap.containsKey(offsetHours)) {
      return timezoneMap[offsetHours]!;
    }

    // Try with half-hour offset (for India, etc.)
    double halfHourOffset = offsetHours + 0.5;
    if (timezoneMap.containsKey(halfHourOffset)) {
      return timezoneMap[halfHourOffset]!;
    }

    // For offsets outside the map, use closest match or default
    // Clamp offset to reasonable range
    int clampedOffset = offsetHours.clamp(-12, 12);
    return timezoneMap[clampedOffset] ?? "Asia/Karachi";
  }

  Future<void> _calculatePrayerTimes(DateTime date) async {
    if (!locationAllowed) {
      debugPrint(
        'Cannot calculate prayer times: locationAllowed=$locationAllowed',
      );
      return;
    }

    try {
      // Update calculation parameters based on selected methods
      _updateCalculationParams();

      // Use current position if available, else use default coordinates
      Coordinates coords;
      if (currentPosition != null) {
        coords = Coordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
      } else {
        coords = coordinates;
      }

      // Create a new PrayerTimes instance for the specific date
      // Note: Some versions may not support dateTime parameter, so we'll try both approaches
      PrayerTimes prayerTimes;
      try {
        prayerTimes = PrayerTimes(
          coordinates: coords,
          calculationParameters: params,
          precision: true,
          locationName: timezoneName.isNotEmpty ? timezoneName : 'Asia/Karachi',
          dateTime: date,
        );
      } catch (e) {
        // If dateTime parameter doesn't work, try without it (will use current date)
        debugPrint('Trying without dateTime parameter: $e');
        prayerTimes = PrayerTimes(
          coordinates: coords,
          calculationParameters: params,
          precision: true,
          locationName: timezoneName.isNotEmpty ? timezoneName : 'Asia/Karachi',
        );
      }

      _prayerTimes = prayerTimes;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Clear existing list before adding new times
      List<NamazModel> newNamazList = [];

      if (prayerTimes.fajrStartTime != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.fajrStartTime!),
            name: "Fajr",
            speakerEnabled: prefs.getString("fajrSpeaker") ?? "on",
          ),
        );
      }

      if (prayerTimes.sunrise != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.sunrise!),
            name: "Sunrise",
            speakerEnabled: prefs.getString("sunriseSpeaker") ?? "on",
          ),
        );
      }

      if (prayerTimes.dhuhrStartTime != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.dhuhrStartTime!),
            name: "Dhuhr",
            speakerEnabled: prefs.getString("dhuhrSpeaker") ?? "on",
          ),
        );
      }

      if (prayerTimes.asrStartTime != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.asrStartTime!),
            name: "Asr",
            speakerEnabled: prefs.getString("asrSpeaker") ?? "on",
          ),
        );
      }

      if (prayerTimes.maghribStartTime != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.maghribStartTime!),
            name: "Maghrib",
            speakerEnabled: prefs.getString("maghribSpeaker") ?? "on",
          ),
        );
        // Using Maghrib as proxy for Sunset as requested
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.maghribStartTime!),
            name: "Sunset",
            speakerEnabled: prefs.getString("sunsetSpeaker") ?? "on",
          ),
        );
      }

      if (prayerTimes.ishaStartTime != null) {
        newNamazList.add(
          NamazModel(
            time: DateFormat('hh:mm a').format(prayerTimes.ishaStartTime!),
            name: "Ishaa",
            speakerEnabled: prefs.getString("ishaSpeaker") ?? "on",
          ),
        );
      }

      setState(() {
        _namazList.clear();
        _namazList.addAll(newNamazList);
        isLoadingPrayerTimes = false;
      });

      debugPrint(
        'Prayer times calculated successfully. List length: ${_namazList.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('Error calculating prayer times: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _namazList.clear();
        isLoadingPrayerTimes = false;
      });
    }
  }

  setPosition() async {
    try {
      Position? position;
      try {
        position = await _determinePosition();
        currentPosition = position;
      } catch (e) {
        debugPrint('Error getting position: $e');
        // If permission denied or error, use default coordinates (Lahore, Pakistan)
        // Create a mock position using coordinates directly
        locationAllowed = true;
        locationName = "Lahore, Pakistan";
        timezoneName = "Asia/Karachi";

        // We'll handle this in _calculatePrayerTimes by using coordinates directly
        coordinates = Coordinates(31.5497, 74.3436);
        setState(() {});
      }

      // Always calculate prayer times - use current position if available, else default coordinates
      if (locationAllowed) {
        // Get location name from coordinates (non-blocking if it fails)
        if (currentPosition != null) {
          try {
            await _getLocationName(currentPosition!);
          } catch (e) {
            debugPrint('Error getting location name: $e');
            // Continue anyway with default location name
          }
        }

        // Calculate prayer times for the selected date
        await _calculatePrayerTimes(selectedEnglishDate);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in setPosition: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to default location
      locationAllowed = true;
      locationName = "Lahore, Pakistan";
      timezoneName = "Asia/Karachi";
      coordinates = Coordinates(31.5497, 74.3436);
      setState(() {});
      // Try to calculate with default coordinates
      await _calculatePrayerTimes(selectedEnglishDate);
    }
  }

  void _incrementDate() {
    // Increment the day by 1
    selectedHijriDate.hDay++;
    selectedEnglishDate = selectedEnglishDate.add(Duration(days: 1));

    // Handle month overflow (assuming month has up to 30 days)
    if (selectedHijriDate.hDay > 30) {
      selectedHijriDate.hDay = 1;
      selectedHijriDate.hMonth++;

      // Handle year overflow
      if (selectedHijriDate.hMonth > 12) {
        selectedHijriDate.hMonth = 1;
        selectedHijriDate.hYear++;
      }
    }

    selectedHijriDate.hijriToGregorian(
      selectedHijriDate.hYear,
      selectedHijriDate.hMonth,
      selectedHijriDate.hDay,
    );

    // Recalculate prayer times for the new date
    _calculatePrayerTimes(selectedEnglishDate);

    setState(() {
      // Update UI
    });
    selectedHijriDate.hijriToGregorian(
      selectedHijriDate.hYear,
      selectedHijriDate.hMonth,
      selectedHijriDate.hDay,
    );
    // Print the next Hijri date
    debugPrint('Next Hijri Date: ${selectedHijriDate.toFormat("dd MM yyyy")}');
  }

  void _decrementDate() {
    // Decrement the day by 1
    selectedHijriDate.hDay--;
    selectedEnglishDate = selectedEnglishDate.subtract(Duration(days: 1));

    // Handle month underflow (when day is less than 1)
    if (selectedHijriDate.hDay < 1) {
      selectedHijriDate.hMonth--;

      // Handle year underflow
      if (selectedHijriDate.hMonth < 1) {
        selectedHijriDate.hMonth = 12;
        selectedHijriDate.hYear--;
      }

      // Set the day to the last day of the previous Hijri month (assume 30 days for simplicity)
      selectedHijriDate.hDay = 30;
    }

    selectedHijriDate.hijriToGregorian(
      selectedHijriDate.hYear,
      selectedHijriDate.hMonth,
      selectedHijriDate.hDay,
    );

    // Recalculate prayer times for the new date
    _calculatePrayerTimes(selectedEnglishDate);

    setState(() {
      // Update UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Premium Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E), // Deep Spirit Blue
                  Color(0xFF3949AB), // Indigo
                  Color(0xFF5C6BC0), // Soft Indigo
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Subtle Islamic Pattern Overlay (using existing bg as overlay)
          Opacity(
            opacity: 0.15,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/prayerBg.png"),
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Minimal Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildLocationHeader(), _buildCompassButton()],
                    ),
                  ),
                ),

                // Date Selector
                SliverToBoxAdapter(
                  child: _buildDateSelector().paddingSymmetric(vertical: 20),
                ),

                // Next Prayer Highlights
                if (locationAllowed &&
                    !isLoadingPrayerTimes &&
                    _nextPrayerName.isNotEmpty)
                  SliverToBoxAdapter(
                    child: FadeInAnimationTTB(
                      delay: 0.3,
                      child: _buildNextPrayerCard(),
                    ).paddingSymmetric(horizontal: 20, vertical: 10),
                  ),

                // Prayer Times List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: locationAllowed
                      ? isLoadingPrayerTimes
                            ? const SliverFillRemaining(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : _namazList.isEmpty
                            ? const SliverToBoxAdapter(
                                child: Center(
                                  child: Text(
                                    "Unable to load prayer times",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final namaz = _namazList[index];
                                  final isNext = namaz.name == _nextPrayerName;
                                  return FadeInAnimationBTT(
                                    delay: 0.1 * index,
                                    child: NamazTile(
                                      namaz,
                                      index != _namazList.length - 1,
                                      isNext: isNext,
                                    ),
                                  );
                                }, childCount: _namazList.length),
                              )
                      : const SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              "Location is not enabled",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ),

                // Calculation Methods
                if (locationAllowed)
                  SliverToBoxAdapter(
                    child: FadeInAnimationBTT(
                      delay: 0.8,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _CalculationMethodDropdown(
                                selectedValue: selectedCalculationMethod,
                                onChanged: (String value) async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    "calculationMethod",
                                    value,
                                  );
                                  setState(() {
                                    selectedCalculationMethod = value;
                                  });
                                  _updateCalculationParams();
                                  await _calculatePrayerTimes(
                                    selectedEnglishDate,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _JuristicMethodDropdown(
                                selectedValue: selectedJuristicMethod,
                                onChanged: (String value) async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    "juristicMethod",
                                    value,
                                  );
                                  setState(() {
                                    selectedJuristicMethod = value;
                                  });
                                  _updateCalculationParams();
                                  await _calculatePrayerTimes(
                                    selectedEnglishDate,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                "LOCATION".tr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            locationName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompassButton() {
    return InkWell(
      onTap: () {
        if (locationAllowed) {
          Get.to(
            CompassScreen(
              latitude: currentPosition?.latitude ?? coordinates.latitude,
              longitude: currentPosition?.longitude ?? coordinates.longitude,
            ),
            transition: Transition.cupertino,
          );
        } else {
          if (Get.context != null) {
            Get.snackbar(
              "Location required",
              "Please enable location",
              backgroundColor: Colors.red,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: _decrementDate,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  selectedHijriDate.toFormat("dd MMMM yyyy"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(selectedEnglishDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: _incrementDate,
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String hours = twoDigits(d.inHours);
      String minutes = twoDigits(d.inMinutes.remainder(60));
      String seconds = twoDigits(d.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NEXT PRAYER".tr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _nextPrayerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time_filled_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    formatDuration(_timeToNextPrayer),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    "remaining until Adhan".tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NamazTile extends StatefulWidget {
  final NamazModel _namazModel;
  final bool bottomLine;
  final bool isNext;

  const NamazTile(
    this._namazModel,
    this.bottomLine, {
    super.key,
    this.isNext = false,
  });

  @override
  State<NamazTile> createState() => _NamazTileState();
}

class _NamazTileState extends State<NamazTile> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isNext
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isNext
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: widget.isNext ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isNext
                  ? rwhite.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _getPrayerIcon(widget._namazModel.name),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget._namazModel.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isNext
                            ? FontWeight.w900
                            : FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.isNext)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "NEXT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  widget._namazModel.time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _buildVolumeAction(),
        ],
      ),
    );
  }

  Widget _buildVolumeAction() {
    return InkWell(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          if (widget._namazModel.speakerEnabled == "on") {
            widget._namazModel.speakerEnabled = "off";
            _saveSpeakerSetting(prefs, widget._namazModel.name, "off");
          } else if (widget._namazModel.speakerEnabled == "off") {
            widget._namazModel.speakerEnabled = "vibrate";
            _saveSpeakerSetting(prefs, widget._namazModel.name, "vibrate");
          } else {
            widget._namazModel.speakerEnabled = "on";
            _saveSpeakerSetting(prefs, widget._namazModel.name, "on");
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          widget._namazModel.speakerEnabled == "on"
              ? Icons.notifications_active_rounded
              : widget._namazModel.speakerEnabled == "off"
              ? Icons.notifications_off_rounded
              : Icons.vibration_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'sunrise':
        return Icons.wb_sunny_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_rounded;
      case 'asr':
        return Icons.wb_cloudy_rounded;
      case 'maghrib':
        return Icons.wb_twilight_rounded;
      case 'sunset':
        return Icons.wb_twilight_rounded;
      case 'ishaa':
        return Icons.nightlight_round;
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  void _saveSpeakerSetting(SharedPreferences prefs, String name, String value) {
    String key = "";
    switch (name) {
      case "Fajr":
        key = "fajrSpeaker";
        break;
      case "Sunrise":
        key = "sunriseSpeaker";
        break;
      case "Dhuhr":
        key = "dhuhrSpeaker";
        break;
      case "Asr":
        key = "asrSpeaker";
        break;
      case "Maghrib":
        key = "maghribSpeaker";
        break;
      case "Sunset":
        key = "sunsetSpeaker";
        break;
      case "Ishaa":
        key = "ishaSpeaker";
        break;
    }
    if (key.isNotEmpty) {
      prefs.setString(key, value);
    }
  }
}

// Calculation Method Dropdown Widget
class _CalculationMethodDropdown extends StatelessWidget {
  final String selectedValue;
  final Function(String) onChanged;

  const _CalculationMethodDropdown({
    required this.selectedValue,
    required this.onChanged,
  });

  final List<Map<String, String>> _items = const [
    {'value': 'ummAlQura', 'label': 'Umm Al-Qura'},
    {'value': 'muslimWorldLeague', 'label': 'Muslim World League'},
    {'value': 'northAmerica', 'label': 'North America'},
    {'value': 'egyptian', 'label': 'Egyptian'},
    {'value': 'singapore', 'label': 'Singapore'},
    {'value': 'karachi', 'label': 'Karachi'},
  ];

  String _getLabel(String value) {
    final item = _items.firstWhere(
      (item) => item['value'] == value,
      orElse: () => _items[0],
    );
    return item['label']!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: rwhite.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rwhite),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calculation Method",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: rwhite.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                _getLabel(selectedValue),
                style: TextStyle(
                  fontSize: 14,
                  color: rwhite,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Calculation Method",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: rblack,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: rbluedark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Options
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = item['value'] == selectedValue;

                      return ListTile(
                        title: Text(
                          item['label']!,
                          style: TextStyle(
                            color: isSelected ? rbluedark : rblack,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: rbluedark)
                            : null,
                        selected: isSelected,
                        onTap: () {
                          onChanged(item['value']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Juristic Method Dropdown Widget
class _JuristicMethodDropdown extends StatelessWidget {
  final String selectedValue;
  final Function(String) onChanged;

  const _JuristicMethodDropdown({
    required this.selectedValue,
    required this.onChanged,
  });

  final List<Map<String, String>> _items = const [
    {'value': 'shafi', 'label': 'Shafi/Maliki/Hanbali'},
    {'value': 'hanafi', 'label': 'Hanafi'},
  ];

  String _getLabel(String value) {
    if (value == 'shafi') {
      return 'Shafi/Maliki/Hanbali';
    }
    return 'Hanafi';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: rwhite.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rwhite),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Juristic Method",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: rwhite.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                _getLabel(selectedValue),
                style: TextStyle(
                  fontSize: 14,
                  color: rwhite,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Juristic Method",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: rblack,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: rbluedark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Options
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = item['value'] == selectedValue;

                      return ListTile(
                        title: Text(
                          item['label']!,
                          style: TextStyle(
                            color: isSelected ? rbluedark : rblack,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: rbluedark)
                            : null,
                        selected: isSelected,
                        onTap: () {
                          onChanged(item['value']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
