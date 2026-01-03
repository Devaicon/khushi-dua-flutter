import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  final List<NamazModel> _namazList = [];

  var fajrVolume = "on";
  var sunriseVolume = "on";
  var dhuhrVolume = "on";
  var asrVolume = "on";
  var maghribVolume = "on";
  var ishaaVolume = "on";

  @override
  void initState() {
    super.initState();
    setPosition();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationAllowed = false;
        });
        return Future.error('Location permissions are denied');
      } else {
        setState(() {
          locationAllowed = true;
        });
      }
    } else if (permission == LocationPermission.deniedForever) {
    } else {
      setState(() {
        locationAllowed = true;
      });
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  setPosition() async {
    currentPosition = await _determinePosition();
    setState(() {
      currentPosition;
    });
    params.madhab = PrayerMadhab.shafi;

    PrayerTimes prayerTimes = PrayerTimes(
      coordinates: Coordinates(
        currentPosition?.latitude ?? 0,
        currentPosition?.longitude ?? 0,
      ),
      calculationParameters: params,
      precision: true,
      locationName: 'Asia/Karachi',
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    NamazModel fajr = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.fajrStartTime!),
      name: "Fajr",
      speakerEnabled: "on",
    );
    NamazModel sunrise = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.sunrise!),
      name: "Sunrise",
      speakerEnabled: "on",
    );
    NamazModel dhuhr = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.dhuhrStartTime!),
      name: "Dhuhr",
      speakerEnabled: "on",
    );
    NamazModel asr = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.asrStartTime!),
      name: "Asr",
      speakerEnabled: "on",
    );
    NamazModel maghrib = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.maghribStartTime!),
      name: "Maghrib",
      speakerEnabled: "on",
    );
    NamazModel isha = NamazModel(
      time: DateFormat('hh:mm a').format(prayerTimes.ishaStartTime!),
      name: "Ishaa",
      speakerEnabled: "on",
    );
    fajr.speakerEnabled = prefs.getString("fajrSpeaker") ?? "on";
    sunrise.speakerEnabled = prefs.getString("sunriseSpeaker") ?? "on";
    dhuhr.speakerEnabled = prefs.getString("dhuhrSpeaker") ?? "on";
    asr.speakerEnabled = prefs.getString("aasrSpeaker") ?? "on";
    maghrib.speakerEnabled = prefs.getString("maghribSpeaker") ?? "on";
    isha.speakerEnabled = prefs.getString("ishaSpeaker") ?? "on";

    _namazList.add(fajr);
    _namazList.add(sunrise);
    _namazList.add(dhuhr);
    _namazList.add(asr);
    _namazList.add(maghrib);
    _namazList.add(isha);
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

    setState(() {
      selectedHijriDate;
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

    setState(() {
      selectedHijriDate;
    });
    selectedHijriDate.hijriToGregorian(
      selectedHijriDate.hYear,
      selectedHijriDate.hMonth,
      selectedHijriDate.hDay,
    );
    // Print the previous Hijri date
    debugPrint(
      'Previous Hijri Date: ${selectedHijriDate.toFormat("dd MM yyyy")}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image: AssetImage("assets/images/prayerBg.png"),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      if (locationAllowed) {
                        Get.to(
                          CompassScreen(
                            latitude: currentPosition?.latitude ?? 0,
                            longitude: currentPosition?.longitude ?? 0,
                          ),
                          transition: Transition.fade,
                        );
                      } else {
                        Get.snackbar(
                          "Location required",
                          "Please enable location permissions from your phone settings",
                          backgroundColor: Colors.red,
                        );
                      }
                    },
                    child: Image.asset(
                      "assets/images/prayerLocation.png",
                      width: 45,
                      height: 50,
                    ).marginOnly(top: 12),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: rwhite, size: 30),
                    SizedBox(width: 12),
                    Text(
                      "Lahore",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: rwhite,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

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
                                  DateFormat(
                                    'EEEE',
                                  ).format(selectedEnglishDate),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              selectedHijriDate.toFormat("dd MMMM yyyy"),
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              DateFormat(
                                'dd MMMM yyy',
                              ).format(selectedEnglishDate),
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

                SizedBox(height: 20),
                //namaz time
                locationAllowed
                    ? FadeInAnimationTTB(
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
                            },
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          "Location is not enabled",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                SizedBox(height: 20),

                FadeInAnimationBTT(
                  delay: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 80,
                      decoration: BoxDecoration(
                        color: rwhite.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: rwhite),
                      ),
                      child: Divider(height: 2, color: rwhite),
                    ),
                  ),
                ),
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
                widget._namazModel.time,
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget._namazModel.name,
                style: TextStyle(fontSize: 20),
              ).marginSymmetric(horizontal: 10),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();

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
              ),
            ),
          ],
        ).marginSymmetric(horizontal: 12, vertical: 8),
        if (widget.bottomLine) Divider(height: 2, color: rwhite),
      ],
    );
  }
}
