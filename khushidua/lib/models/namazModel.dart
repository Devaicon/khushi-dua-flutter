import '../constants/prayerNames.dart';

class NamazModel {
  String time = '';
  String name = '';
  String speakerEnabled = 'true';

  NamazModel({
    required this.time,
    required this.name,
    required this.speakerEnabled,
  });

  /// The Arabic name shown beside the English one, or an empty string when
  /// there is no Arabic name for this row.
  String get arabicName => arabicPrayerName(name);
}
