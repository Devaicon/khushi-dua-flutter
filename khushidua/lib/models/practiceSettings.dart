/// The Practice button's switch and its transcription server, set from the
/// admin panel's ML Settings tab at `SystemConfiguration/MemoizationURL`.
///
/// A missing document or field behaves as the app did before the switch
/// existed: Practice on, using the server the app shipped with.
class PracticeSettings {
  static const String docId = 'MemoizationURL';
  static const String fallbackUrl = 'http://34.238.195.141:3400/transcribe/';

  const PracticeSettings({this.enabled = true, this.url = fallbackUrl});

  /// Whether the Practice button is live; off shows it greyed out.
  final bool enabled;

  /// Where recordings are sent to be transcribed.
  final String url;

  factory PracticeSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PracticeSettings();
    final url = map['URL'];
    return PracticeSettings(
      enabled: map['practiceEnabled'] is bool
          ? map['practiceEnabled'] as bool
          : true,
      url: url is String && url.trim().isNotEmpty ? url.trim() : fallbackUrl,
    );
  }
}
