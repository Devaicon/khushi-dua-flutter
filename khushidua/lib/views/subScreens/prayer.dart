import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../controllers/prayerSettingsController.dart';
import '../../controllers/reminderController.dart';
import '../../helpers/nextPrayer.dart';
import '../../helpers/reminderSchedule.dart';
import '../../models/namazModel.dart';
import '../../widgets/salahBanner.dart';
import '../../widgets/skeleton.dart';
import '../dashboard.dart';
import '../subSettings/prayerTimeSettings.dart';
import '../subSettings/salahReminderSettings.dart';
import '../../widgets/donateCard.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  HijriCalendar selectedHijriDate = HijriCalendar.now();
  DateTime selectedEnglishDate = DateTime.now();

  Coordinates coordinates = Coordinates(21.1959, 72.7933);

  PrayerCalculationParameters get params =>
      Get.find<PrayerSettingsController>().parameters;
  Position? currentPosition;

  bool locationAllowed = false;
  bool isLoadingPrayerTimes = true;
  String locationName = "Loading...";
  String timezoneName = "UTC"; // Default timezone

  final List<NamazModel> _namazList = [];

  Timer? _timer;
  Duration _timeToNextPrayer = Duration.zero;
  String _nextPrayerName = "";

  /// Today's and tomorrow's times, whatever day is being browsed. The
  /// countdown card and the reminders always work from these.
  PrayerTimes? _todayTimes;
  PrayerTimes? _tomorrowTimes;
  DateTime? _todayDate;

  VoidCallback? _stopWatchingSettings;
  String? _appliedSettings;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<PrayerSettingsController>();
    _appliedSettings = '${settings.method}/${settings.madhab}';
    _stopWatchingSettings = settings.addListener(_onSettingsChanged);
    setPosition();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _stopWatchingSettings?.call();
    _timer?.cancel();
    super.dispose();
  }

  /// A new calculation or juristic method, chosen on the Prayer Times
  /// settings screen, recalculates everything shown.
  void _onSettingsChanged() {
    final settings = Get.find<PrayerSettingsController>();
    final key = '${settings.method}/${settings.madhab}';
    if (key == _appliedSettings || !mounted) return;
    _appliedSettings = key;
    _calculatePrayerTimes(selectedEnglishDate);
  }

  bool get _browsingToday =>
      DateUtils.isSameDay(selectedEnglishDate, DateTime.now());

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  /// Today's start time for a schedulable prayer, if it is available.
  DateTime? _prayerTimeFor(String prayer) {
    switch (prayer) {
      case "Fajr":
        return _todayTimes?.fajrStartTime;
      case "Dhuhr":
        return _todayTimes?.dhuhrStartTime;
      case "Asr":
        return _todayTimes?.asrStartTime;
      case "Maghrib":
        return _todayTimes?.maghribStartTime;
      case "Ishaa":
        return _todayTimes?.ishaStartTime;
      default:
        return null;
    }
  }

  void _calculateNextPrayer() {
    final now = DateTime.now();
    // Past midnight, "today" has moved on: recompute it, and the reminders.
    if (_todayDate != null && !DateUtils.isSameDay(_todayDate, now)) {
      _refreshToday();
    }
    final today = _todayTimes;
    if (today == null) return;

    final next = nextPrayerAfter(
      now: now,
      today: {
        "Fajr": today.fajrStartTime,
        "Sunrise": today.sunrise,
        "Dhuhr": today.dhuhrStartTime,
        "Asr": today.asrStartTime,
        "Maghrib": today.maghribStartTime,
        "Ishaa": today.ishaStartTime,
      },
      tomorrowFajr: _tomorrowTimes?.fajrStartTime,
    );

    setState(() {
      _nextPrayerName = next?.name ?? "";
      _timeToNextPrayer = next == null
          ? Duration.zero
          : next.time.difference(now);
    });
  }

  Coordinates get _coordinates => currentPosition != null
      ? Coordinates(currentPosition!.latitude, currentPosition!.longitude)
      : coordinates;

  PrayerTimes _timesFor(DateTime date) => PrayerTimes(
    coordinates: _coordinates,
    calculationParameters: params,
    precision: true,
    locationName: timezoneName.isNotEmpty ? timezoneName : 'Asia/Karachi',
    dateTime: date,
  );

  /// Recomputes today and tomorrow, and re-arms the Salah reminders from
  /// today's times — never from a day the reader has paged to.
  Future<void> _refreshToday() async {
    final now = DateTime.now();
    try {
      _todayDate = now;
      _todayTimes = _timesFor(now);
      _tomorrowTimes = _timesFor(DateTime(now.year, now.month, now.day + 1));
    } catch (e) {
      debugPrint('Error calculating today\'s prayer times: $e');
      return;
    }
    _calculateNextPrayer();
    // Safe to call when the reminders are off: the controller cancels.
    await Get.find<ReminderController>().syncSalahReminders({
      for (final prayer in kSchedulablePrayers)
        if (_prayerTimeFor(prayer) != null) prayer: _prayerTimeFor(prayer)!,
    });
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
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
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

  /// Fills the list for [date]. [refreshToday] is off when the reader only
  /// pages to another day, which changes nothing about today.
  Future<void> _calculatePrayerTimes(
    DateTime date, {
    bool refreshToday = true,
  }) async {
    if (!locationAllowed) {
      debugPrint(
        'Cannot calculate prayer times: locationAllowed=$locationAllowed',
      );
      return;
    }

    try {
      final coords = _coordinates;

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

      // The location or method may have changed, so today's times too.
      if (refreshToday) await _refreshToday();

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
    _calculatePrayerTimes(selectedEnglishDate, refreshToday: false);

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
    _calculatePrayerTimes(selectedEnglishDate, refreshToday: false);

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

          // The dashboard already applies the system SafeArea; a second one
          // here added nothing, and the header sat flush against the top.
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Minimal Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.xl,
                    AppSpace.lg,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLocationHeader(),
                      // Qibla on the left of the method button, both pinned
                      // to the top rather than the method sitting at the end
                      // of the list.
                      _headerButton(
                        icon: Icons.explore_rounded,
                        tooltip: "Qibla Direction".tr,
                        // The compass is a tab of its own; this is a
                        // shortcut to it.
                        onTap: () => AppTabs.go(AppTabs.qibla),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _headerButton(
                        icon: Icons.tune_rounded,
                        tooltip: "Prayer Times".tr,
                        onTap: () => Get.to(
                          () => const PrayerTimeSettings(),
                          transition: Transition.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Salah time banner
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SalahBanner(bottomGap: AppSpace.md),
                ),
              ),

              // Date Selector
              SliverToBoxAdapter(
                child: _buildDateSelector().paddingSymmetric(vertical: 20),
              ),

              // Next Prayer Highlights
              // A shimmering placeholder while the times are worked out, so
              // the card does not pop in and push the list down.
              if (isLoadingPrayerTimes)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _NextPrayerSkeleton(),
                  ),
                )
              else if (locationAllowed && _nextPrayerName.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildNextPrayerCard().paddingSymmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),

              // Prayer Times List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                // The skeleton comes first: locationAllowed is still false
                // while the position is being fetched, which used to flash
                // "Location is not enabled" before the times appeared.
                sliver: isLoadingPrayerTimes
                    ? const SliverToBoxAdapter(child: _PrayerListSkeleton())
                    : locationAllowed
                    ? _namazList.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  "Unable to load prayer times".tr,
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
                                final isNext =
                                    _browsingToday &&
                                    namaz.name == _nextPrayerName;
                                return NamazTile(
                                  namaz,
                                  index != _namazList.length - 1,
                                  isNext: isNext,
                                );
                              }, childCount: _namazList.length),
                            )
                    : SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            "Location is not enabled".tr,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.sm)),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DonateCard(onDark: true),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
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

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
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

/// Stands in for the prayer list while the location and times are worked
/// out. Rows match [NamazTile]'s size so nothing jumps when the times land.
/// Stands in for the next-prayer card while the times load.
class _NextPrayerSkeleton extends StatelessWidget {
  const _NextPrayerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      onDark: true,
      child: Container(
        // Matches the real card's size and corners, measured on a device.
        height: 206,
        padding: const EdgeInsets.all(AppSpace.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 90, height: 12, radius: 6),
            SizedBox(height: AppSpace.sm),
            SkeletonBox(width: 120, height: 26, radius: 8),
            Spacer(),
            SkeletonBox(width: 200, height: 36, radius: 10),
          ],
        ),
      ),
    );
  }
}

class _PrayerListSkeleton extends StatelessWidget {
  const _PrayerListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      onDark: true,
      child: Column(
        children: [
          for (int i = 0; i < 6; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Faint enough that only the shapes inside read as solid.
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 40, height: 40, radius: 15),
                  SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SkeletonBox(width: 90, height: 14, radius: 6),
                    ),
                  ),
                  SkeletonBox(width: 64, height: 14, radius: 6),
                  SizedBox(width: 16),
                  SkeletonBox(width: 24, height: 24, radius: 12),
                ],
              ),
            ),
        ],
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
                      widget._namazModel.name.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isNext
                            ? FontWeight.w900
                            : FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget._namazModel.arabicName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget._namazModel.arabicName,
                        style: TextStyle(
                          fontFamily: 'arabic',
                          fontSize: 16,
                          color: Colors.white.withOpacity(
                            widget.isNext ? 0.9 : 0.7,
                          ),
                        ),
                      ),
                    ],
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
                        child: Text(
                          "NEXT".tr,
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

  /// Shows how this prayer's reminder will alert. Changing it happens on the
  /// Salah Reminders screen, the one place those settings live, so a tap here
  /// opens it rather than silently cycling through modes.
  Widget _buildVolumeAction() {
    // Sunrise and Sunset are listed for reference but carry no reminder.
    if (!kSchedulablePrayers.contains(widget._namazModel.name)) {
      return const SizedBox(width: 34);
    }
    return GetBuilder<ReminderController>(
      builder: (reminders) {
        final alert = reminders.salahEnabled
            ? salahAlertFor(widget._namazModel.speakerEnabled)
            : SalahAlert.off;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await Get.to(
              () => const SalahReminderSettings(),
              transition: Transition.fade,
            );
            final prefs = await SharedPreferences.getInstance();
            final mode =
                prefs.getString(salahSpeakerKeyFor(widget._namazModel.name)) ??
                "on";
            if (mounted) {
              setState(() => widget._namazModel.speakerEnabled = mode);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              switch (alert) {
                SalahAlert.sound => Icons.notifications_active_rounded,
                SalahAlert.vibrate => Icons.vibration_rounded,
                SalahAlert.off => Icons.notifications_off_rounded,
              },
              color: alert == SalahAlert.off
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white,
              size: 18,
            ),
          ),
        );
      },
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
}
