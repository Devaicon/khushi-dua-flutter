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

  List<NamazModel> _namazList = [];

  // Calculation and Juristic Method state
  String selectedCalculationMethod = "karachi";
  String selectedJuristicMethod = "shafi";

  var fajrVolume = "on";
  var sunriseVolume = "on";
  var dhuhrVolume = "on";
  var asrVolume = "on";
  var maghribVolume = "on";
  var ishaaVolume = "on";

  @override
  void initState() {
    super.initState();
    _loadPrayerSettings();
  }

  Future<void> _loadPrayerSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCalculationMethod = prefs.getString("calculationMethod") ?? "karachi";
      selectedJuristicMethod = prefs.getString("juristicMethod") ?? "shafi";
    });
    _updateCalculationParams();
    setPosition();
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
      print('Error updating calculation params: $e');
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
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
        String city = place.locality ?? place.subAdministrativeArea ?? "";
        String country = place.country ?? "";
        String isoCountryCode = place.isoCountryCode ?? "";
        
        // Determine timezone based on coordinates (simplified approach)
        // You can use a timezone package for more accurate timezone detection
        if (isoCountryCode.isNotEmpty) {
          // Common timezone mappings (simplified)
          if (isoCountryCode == "PK") {
            timezoneName = "Asia/Karachi";
          } else if (isoCountryCode == "IN") {
            timezoneName = "Asia/Kolkata";
          } else if (isoCountryCode == "SA") {
            timezoneName = "Asia/Riyadh";
          } else if (isoCountryCode == "AE") {
            timezoneName = "Asia/Dubai";
          } else {
            // Use a mapping of UTC offsets to valid IANA timezone names
            // 1 hour = 15 degrees of longitude
            int offsetHours = (position.longitude / 15).round();
            timezoneName = _getTimezoneFromOffset(offsetHours);
          }
        } else {
          // If no country code, use default timezone based on coordinates
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
      setState(() {
        locationName = "Unknown location";
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
      print('Cannot calculate prayer times: locationAllowed=$locationAllowed');
      return;
    }

    try {
      // Update calculation parameters based on selected methods
      _updateCalculationParams();

      // Use current position if available, else use default coordinates
      Coordinates coords;
      if (currentPosition != null) {
        coords = Coordinates(currentPosition!.latitude, currentPosition!.longitude);
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
        print('Trying without dateTime parameter: $e');
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
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.fajrStartTime!),
          name: "Fajr",
          speakerEnabled: prefs.getString("fajrSpeaker") ?? "on"
        ));
      }
      
      if (prayerTimes.sunrise != null) {
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.sunrise!),
          name: "Sunrise",
          speakerEnabled: prefs.getString("sunriseSpeaker") ?? "on"
        ));
      }
      
      if (prayerTimes.dhuhrStartTime != null) {
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.dhuhrStartTime!),
          name: "Dhuhr",
          speakerEnabled: prefs.getString("dhuhrSpeaker") ?? "on"
        ));
      }
      
      if (prayerTimes.asrStartTime != null) {
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.asrStartTime!),
          name: "Asr",
          speakerEnabled: prefs.getString("asrSpeaker") ?? "on"
        ));
      }
      
      if (prayerTimes.maghribStartTime != null) {
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.maghribStartTime!),
          name: "Maghrib",
          speakerEnabled: prefs.getString("maghribSpeaker") ?? "on"
        ));
      }
      
      if (prayerTimes.ishaStartTime != null) {
        newNamazList.add(NamazModel(
          time: DateFormat('hh:mm a').format(prayerTimes.ishaStartTime!),
          name: "Ishaa",
          speakerEnabled: prefs.getString("ishaSpeaker") ?? "on"
        ));
      }

      setState(() {
        _namazList = newNamazList;
        isLoadingPrayerTimes = false;
      });
      
      print('Prayer times calculated successfully. List length: ${_namazList.length}');
    } catch (e, stackTrace) {
      print('Error calculating prayer times: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _namazList = [];
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
        print('Error getting position: $e');
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
            print('Error getting location name: $e');
            // Continue anyway with default location name
          }
        }
        
        // Calculate prayer times for the selected date
        await _calculatePrayerTimes(selectedEnglishDate);
      }
    } catch (e, stackTrace) {
      print('Error in setPosition: $e');
      print('Stack trace: $stackTrace');
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

    selectedHijriDate.hijriToGregorian(selectedHijriDate.hYear, selectedHijriDate.hMonth, selectedHijriDate.hDay);
    
    // Recalculate prayer times for the new date
    _calculatePrayerTimes(selectedEnglishDate);
    
    setState(() {
      // Update UI
    });
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
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(image: DecorationImage(fit: BoxFit.fill, image: AssetImage("assets/images/prayerBg.png"))),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        if (locationAllowed) {
                          Get.to(CompassScreen(latitude: currentPosition?.latitude ?? 0, longitude: currentPosition?.longitude ?? 0),
                              transition: Transition.fade);
                        } else {
                          Get.snackbar("Location required", "Please enable location permissions from your phone settings",
                              backgroundColor: Colors.red);
                        }
                      },
                      child: Image.asset(
                        "assets/images/prayerLocation.png",
                        width: 45,
                        height: 50,
                      ).marginOnly(top: 12),
                    )),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: rwhite,
                      size: 30,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(
                      locationName,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: rwhite),
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),

                //calender
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: _decrementDate,
                        tooltip: 'Previous Day',
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: Color(0xff2A158F),
                                ),
                                Text(
                                  "${DateFormat('EEEE').format(selectedEnglishDate)}",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              "${selectedHijriDate.toFormat("dd MMMM yyyy")}",
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              "${DateFormat('dd MMMM yyy').format(selectedEnglishDate)}",
                              style: TextStyle(color: rhint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: _incrementDate,
                        tooltip: 'Next Day',
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 20,
                ),
                //namaz time
                locationAllowed
                    ? isLoadingPrayerTimes
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: rwhite),
                            ),
                          )
                        : _namazList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    "Unable to load prayer times",
                                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : FadeInAnimationTTB(
                                delay: 1,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: rwhite.withOpacity(0.2),
                                    border: Border.all(color: rwhite),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _namazList.length,
                                      itemBuilder: (context, index) {
                                        if (index == _namazList.length - 1) {
                                          return NamazTile(_namazList[index], false);
                                        } else {
                                          return NamazTile(_namazList[index], true);
                                        }
                                      }),
                                ),
                              )
                    : Center(
                        child: Text(
                        "Location is not enabled",
                        style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                      )),

                SizedBox(
                  height: 20,
                ),

                // Calculation Method and Juristic Method Dropdowns
                if (locationAllowed)
                  FadeInAnimationBTT(
                    delay: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CalculationMethodDropdown(
                            selectedValue: selectedCalculationMethod,
                            onChanged: (String value) async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString("calculationMethod", value);
                              setState(() {
                                selectedCalculationMethod = value;
                              });
                              _updateCalculationParams();
                              await _calculatePrayerTimes(selectedEnglishDate);
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _JuristicMethodDropdown(
                            selectedValue: selectedJuristicMethod,
                            onChanged: (String value) async {
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString("juristicMethod", value);
                              setState(() {
                                selectedJuristicMethod = value;
                              });
                              _updateCalculationParams();
                              await _calculatePrayerTimes(selectedEnglishDate);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 15,
                ),

                FadeInAnimationBTT(
                  delay: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 50,
                      decoration:
                          BoxDecoration(color: rwhite.withOpacity(0.2), borderRadius: BorderRadius.circular(19), border: Border.all(color: rwhite)),
                      child: Divider(
                        height: 2,
                        color: rwhite,
                      ),
                    ),
                  ),
                )
              ],
            ).marginSymmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}

class NamazTile extends StatefulWidget {
  final NamazModel _namazModel;
  final bool bottomLine;

  const NamazTile(this._namazModel, this.bottomLine, {super.key});

  @override
  State<NamazTile> createState() => _NamazTileState();
}

class _NamazTileState extends State<NamazTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
                flex: 1,
                child: Text(
                  "${widget._namazModel.time}",
                  style: TextStyle(fontSize: 20),
                )),
            Expanded(
                flex: 2,
                child: Text(
                  "${widget._namazModel.name}",
                  style: TextStyle(fontSize: 20),
                ).marginSymmetric(horizontal: 10)),
            Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();

                    setState(() {
                      if (widget._namazModel.speakerEnabled == "on") {
                        widget._namazModel.speakerEnabled = "off";
                        if (widget._namazModel.name == "Fajr") {
                          prefs.setString("fajrSpeaker", "off");
                        }
                        if (widget._namazModel.name == "Sunrise") {
                          prefs.setString("sunriseSpeaker", "off");
                        }
                        if (widget._namazModel.name == "Dhuhr") {
                          prefs.setString("dhuhrSpeaker", "off");
                        }
                        if (widget._namazModel.name == "Asr") {
                          prefs.setString("asrSpeaker", "off");
                        }
                        if (widget._namazModel.name == "Maghrib") {
                          prefs.setString("maghribSpeaker", "off");
                        }
                        if (widget._namazModel.name == "Ishaa") {
                          prefs.setString("ishaSpeaker", "off");
                        }
                      } else if (widget._namazModel.speakerEnabled == "off") {
                        widget._namazModel.speakerEnabled = "vibrate";
                        if (widget._namazModel.name == "Fajr") {
                          prefs.setString("fajrSpeaker", "vibrate");
                        }
                        if (widget._namazModel.name == "Sunrise") {
                          prefs.setString("sunriseSpeaker", "vibrate");
                        }
                        if (widget._namazModel.name == "Dhuhr") {
                          prefs.setString("dhuhrSpeaker", "vibrate");
                        }
                        if (widget._namazModel.name == "Asr") {
                          prefs.setString("asrSpeaker", "vibrate");
                        }
                        if (widget._namazModel.name == "Maghrib") {
                          prefs.setString("maghribSpeaker", "vibrate");
                        }
                        if (widget._namazModel.name == "Ishaa") {
                          prefs.setString("ishaSpeaker", "vibrate");
                        }
                      } else {
                        widget._namazModel.speakerEnabled = "on";
                        if (widget._namazModel.name == "Fajr") {
                          prefs.setString("fajrSpeaker", "on");
                        }
                        if (widget._namazModel.name == "Sunrise") {
                          prefs.setString("sunriseSpeaker", "on");
                        }
                        if (widget._namazModel.name == "Dhuhr") {
                          prefs.setString("dhuhrSpeaker", "on");
                        }
                        if (widget._namazModel.name == "Asr") {
                          prefs.setString("asrSpeaker", "on");
                        }
                        if (widget._namazModel.name == "Maghrib") {
                          prefs.setString("maghribSpeaker", "on");
                        }
                        if (widget._namazModel.name == "Ishaa") {
                          prefs.setString("ishaSpeaker", "on");
                        }
                      }
                    });
                  },
                  child: Icon(
                    widget._namazModel.speakerEnabled == "on"
                        ? Icons.volume_up_rounded
                        : widget._namazModel.speakerEnabled == "off"
                            ? Icons.volume_mute
                            : Icons.vibration,
                    color: rblack,
                  ),
                )),
          ],
        ).marginSymmetric(horizontal: 12, vertical: 8),
        if (widget.bottomLine)
          Divider(
            height: 2,
            color: rwhite,
          )
      ],
    );
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
                          style: TextStyle(color: rbluedark, fontWeight: FontWeight.bold),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                          style: TextStyle(color: rbluedark, fontWeight: FontWeight.bold),
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
