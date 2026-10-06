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
import '../../constants/prayerNames.dart';
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
import '../../widgets/sunPathView.dart';

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
  DateTime? _nextPrayerTime;

  /// How far through the gap between the last prayer and the next one we
  /// are, 0–1, for the bar on the next-prayer card.
  double _prayerProgress = 0;

  /// Today's and tomorrow's times, whatever day is being browsed. The
  /// countdown card and the reminders always work from these.
  PrayerTimes? _todayTimes;
  PrayerTimes? _tomorrowTimes;

  /// Only for yesterday's Isha: before Fajr it is the prayer we are after.
  PrayerTimes? _yesterdayTimes;
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

    final todayMap = {
      "Fajr": today.fajrStartTime,
      "Sunrise": today.sunrise,
      "Dhuhr": today.dhuhrStartTime,
      "Asr": today.asrStartTime,
      "Maghrib": today.maghribStartTime,
      "Ishaa": today.ishaStartTime,
    };
    final next = nextPrayerAfter(
      now: now,
      today: todayMap,
      tomorrowFajr: _tomorrowTimes?.fajrStartTime,
    );

    // The most recent time already passed, today or yesterday's Isha.
    DateTime? previous = _yesterdayTimes?.ishaStartTime;
    for (final time in todayMap.values) {
      if (time != null && !time.isAfter(now)) {
        if (previous == null || time.isAfter(previous)) previous = time;
      }
    }
    double progress = 0;
    if (next != null && previous != null) {
      final span = next.time.difference(previous).inSeconds;
      if (span > 0) {
        progress = (now.difference(previous).inSeconds / span).clamp(0.0, 1.0);
      }
    }

    setState(() {
      _nextPrayerName = next?.name ?? "";
      _nextPrayerTime = next?.time;
      _prayerProgress = progress;
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
      _yesterdayTimes = _timesFor(DateTime(now.year, now.month, now.day - 1));
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

  /// Moves the browsed day by [days]. The Hijri date is derived from the
  /// Gregorian one: stepping it by hand assumed 30-day months, so it drifted
  /// a day at the end of every 29-day month.
  void _shiftDate(int days) {
    final d = selectedEnglishDate;
    _showDate(DateTime(d.year, d.month, d.day + days));
  }

  void _showDate(DateTime date) {
    setState(() {
      selectedEnglishDate = date;
      selectedHijriDate = HijriCalendar.fromDate(date);
    });
    _calculatePrayerTimes(selectedEnglishDate, refreshToday: false);
  }

  @override
  Widget build(BuildContext context) {
    // The light page every other tab uses. The old indigo gradient and
    // pattern made this one screen look like it came from another app.
    return Scaffold(
      backgroundColor: AppSurface.page,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _section(_buildHeader(), top: AppSpace.lg),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: SalahBanner(topGap: AppSpace.lg),
            ),
          ),

          // A shimmering placeholder while the times are worked out, so the
          // card does not pop in and push the list down.
          if (isLoadingPrayerTimes)
            _section(
              GetBuilder<PrayerSettingsController>(
                builder: (settings) =>
                    _NextPrayerSkeleton(sunPath: settings.cardStyle == 'sun'),
              ),
            )
          else if (locationAllowed && _nextPrayerName.isNotEmpty)
            _section(_buildNextPrayerCard()),

          _section(_buildDateSelector()),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              0,
            ),
            // The skeleton comes first: locationAllowed is still false while
            // the position is being fetched, which used to flash "Location is
            // not enabled" before the times appeared.
            sliver: SliverToBoxAdapter(
              child: isLoadingPrayerTimes
                  ? const _PrayerListSkeleton()
                  : !locationAllowed
                  ? _buildMessage("Location is not enabled".tr)
                  : _namazList.isEmpty
                  ? _buildMessage("Unable to load prayer times".tr)
                  : _buildPrayerList(),
            ),
          ),

          _section(const DonateCard()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
        ],
      ),
    );
  }

  /// One row of the screen: the shared gutter, and [top] spacing from the
  /// row above — the same rhythm as the home screen.
  Widget _section(Widget child, {double top = AppSpace.lg}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, top, AppSpace.lg, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Prayer Times".tr,
                style: const TextStyle(
                  color: rtext,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppText.onPageMuted,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      locationName.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppText.onPageMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        // Qibla on the left of the method button, both pinned to the top.
        _headerButton(
          icon: Icons.explore_rounded,
          tooltip: "Qibla Direction".tr,
          // The compass is a tab of its own; this is a shortcut to it.
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
    );
  }

  /// A round white button, like the inbox bell on the home screen.
  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.sm + 2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppElevation.card,
          ),
          child: Icon(icon, color: rbluedark, size: 22),
        ),
      ),
    );
  }

  Widget _buildMessage(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: plainCardDecoration(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppText.onPageMuted, fontSize: 14),
      ),
    );
  }

  Widget _buildDateSelector() {
    final browsingToday = _browsingToday;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.xs,
      ),
      decoration: plainCardDecoration(),
      child: Row(
        children: [
          _dateArrow(Icons.chevron_left_rounded, () => _shiftDate(-1)),
          Expanded(
            child: Column(
              children: [
                Text(
                  selectedHijriDate.toFormat("dd MMMM yyyy"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: rbluedark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(selectedEnglishDate),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppText.onPageMuted, fontSize: 12),
                ),
                // Paging away from today leaves a one-tap way back.
                AnimatedSize(
                  duration: AppMotion.base,
                  curve: AppMotion.curve,
                  child: browsingToday
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xs),
                          child: InkWell(
                            onTap: () => _showDate(DateTime.now()),
                            borderRadius: AppRadius.pillAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: rbluedark.withValues(alpha: 0.08),
                                borderRadius: AppRadius.pillAll,
                              ),
                              child: Text(
                                "Today".tr,
                                style: const TextStyle(
                                  color: rbluedark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          _dateArrow(Icons.chevron_right_rounded, () => _shiftDate(1)),
        ],
      ),
    );
  }

  Widget _dateArrow(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      color: rbluedark,
      style: IconButton.styleFrom(
        backgroundColor: rbluedark.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      return "${twoDigits(d.inHours)}:"
          "${twoDigits(d.inMinutes.remainder(60))}:"
          "${twoDigits(d.inSeconds.remainder(60))}";
    }

    final arabic = arabicPrayerName(_nextPrayerName);
    final at = _nextPrayerTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl - 4),
      decoration: cardDecoration(rbluedark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "NEXT PRAYER".tr,
                  style: TextStyle(
                    color: AppText.onSurfaceMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (at != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm + 2,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('h:mm a').format(at),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _nextPrayerName.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (arabic.isNotEmpty) ...[
                const SizedBox(width: AppSpace.md),
                Text(
                  arabic,
                  style: TextStyle(
                    fontFamily: 'arabic',
                    fontSize: 22,
                    color: AppText.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            formatDuration(_timeToNextPrayer),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
              // Digits of one width, so the countdown does not jitter.
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            "remaining until Adhan".tr,
            style: TextStyle(color: AppText.onSurfaceMuted, fontSize: 12),
          ),
          const SizedBox(height: AppSpace.md),
          // The bar, or the sun's place in the sky, as chosen in the Prayer
          // Times settings.
          GetBuilder<PrayerSettingsController>(
            builder: (settings) {
              final sunrise = _todayTimes?.sunrise;
              final sunset = _todayTimes?.maghribStartTime;
              if (settings.cardStyle == 'sun' &&
                  sunrise != null &&
                  sunset != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: SunPathView(
                    now: DateTime.now(),
                    sunrise: sunrise,
                    sunset: sunset,
                  ),
                );
              }
              return ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: LinearProgressIndicator(
                  value: _prayerProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// All the day's times on one card, divided like a settings group, rather
  /// than a stack of separate tiles.
  Widget _buildPrayerList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
      decoration: plainCardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < _namazList.length; i++)
            NamazTile(
              _namazList[i],
              i != _namazList.length - 1,
              isNext: _browsingToday && _namazList[i].name == _nextPrayerName,
            ),
        ],
      ),
    );
  }
}

/// Stands in for the next-prayer card while the times load, line for line,
/// so nothing moves when the real card replaces it.
class _NextPrayerSkeleton extends StatelessWidget {
  const _NextPrayerSkeleton({this.sunPath = false});

  /// Stands in for the sun path rather than the progress bar.
  final bool sunPath;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.xl - 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 90, height: 14, radius: 6),
            SizedBox(height: AppSpace.sm),
            SkeletonBox(width: 140, height: 34, radius: 8),
            SizedBox(height: AppSpace.md),
            SkeletonBox(width: 170, height: 40, radius: 10),
            SizedBox(height: 2),
            SkeletonBox(width: 120, height: 13, radius: 6),
            SizedBox(height: AppSpace.md),
            if (sunPath) ...const [
              SizedBox(height: AppSpace.xs),
              SkeletonBox(height: 64, radius: 12),
              SizedBox(height: AppSpace.xs),
              SkeletonBox(height: 30, radius: 8),
            ] else
              const SkeletonBox(height: 4, radius: 2),
          ],
        ),
      ),
    );
  }
}

/// Stands in for the prayer list. Rows match [NamazTile]'s size.
class _PrayerListSkeleton extends StatelessWidget {
  const _PrayerListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
      decoration: plainCardDecoration(),
      child: Skeleton(
        child: Column(
          children: [
            for (int i = 0; i < 7; i++)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpace.lg + 2,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  children: [
                    SkeletonBox(width: 36, height: 36, radius: 18),
                    SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SkeletonBox(width: 110, height: 14, radius: 6),
                      ),
                    ),
                    SkeletonBox(width: 64, height: 14, radius: 6),
                    SizedBox(width: AppSpace.md),
                    SkeletonBox(width: 32, height: 32, radius: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One prayer on the day's card: icon, English and Arabic name, time, and
/// how its reminder alerts.
class NamazTile extends StatefulWidget {
  final NamazModel _namazModel;

  /// Draws a hairline under the row; off for the last one.
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
    final namaz = widget._namazModel;
    final isNext = widget.isNext;

    return Column(
      children: [
        AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md - 2,
          ),
          decoration: BoxDecoration(
            color: isNext
                ? rbluedark.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isNext ? rbluedark : rbluedark.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPrayerIcon(namaz.name),
                  color: isNext
                      ? Colors.white
                      : rbluedark.withValues(alpha: 0.7),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        namaz.name.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isNext
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isNext ? rbluedark : rtext,
                        ),
                      ),
                    ),
                    if (namaz.arabicName.isNotEmpty) ...[
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        namaz.arabicName,
                        style: TextStyle(
                          fontFamily: 'arabic',
                          fontSize: 15,
                          color: AppText.onPageMuted,
                        ),
                      ),
                    ],
                    if (isNext)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpace.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rbluedark,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          "NEXT".tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                namaz.time,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                  color: isNext ? rbluedark : rtext,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _buildVolumeAction(),
            ],
          ),
        ),
        if (widget.bottomLine)
          Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            endIndent: AppSpace.lg,
            color: rbluedark.withValues(alpha: 0.05),
          ),
      ],
    );
  }

  /// Shows how this prayer's reminder will alert. Changing it happens on the
  /// Salah Reminders screen, the one place those settings live, so a tap here
  /// opens it rather than silently cycling through modes.
  Widget _buildVolumeAction() {
    // Sunrise and Sunset are listed for reference but carry no reminder.
    if (!kSchedulablePrayers.contains(widget._namazModel.name)) {
      return const SizedBox(width: 32);
    }
    return GetBuilder<ReminderController>(
      builder: (reminders) {
        final alert = reminders.salahEnabled
            ? salahAlertFor(widget._namazModel.speakerEnabled)
            : SalahAlert.off;
        return InkWell(
          customBorder: const CircleBorder(),
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
          child: SizedBox.square(
            dimension: 32,
            child: Icon(
              switch (alert) {
                SalahAlert.sound => Icons.notifications_active_rounded,
                SalahAlert.vibrate => Icons.vibration_rounded,
                SalahAlert.off => Icons.notifications_off_rounded,
              },
              color: alert == SalahAlert.off
                  ? rbluedark.withValues(alpha: 0.3)
                  : rbluedark.withValues(alpha: 0.75),
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
        return Icons.wb_sunny_outlined;
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
