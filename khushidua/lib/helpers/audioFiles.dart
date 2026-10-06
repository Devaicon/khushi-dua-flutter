/// Naming for downloaded dua audio.
///
/// Kept free of Flutter and plugin imports so it can be unit tested.
library;

/// The file a recording at [url] is saved as.
///
/// Derived from the whole URL, token included, so a recording the admin
/// re-uploads gets a new name and is downloaded again instead of the stale
/// copy being played. Playback looks files up the same way, so no index of
/// downloads needs to be kept.
String audioFileNameFor(String url) {
  final hash = _fnv1a64(url);
  // Dart ints are signed, so print the two 32-bit halves rather than the
  // whole value, which would come out negative half the time.
  final high = (hash >>> 32).toRadixString(16).padLeft(8, '0');
  final low = (hash & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return 'audio_$high$low.mp3';
}

/// 64-bit FNV-1a over the UTF-16 code units. Stable across runs and Dart
/// versions, unlike [String.hashCode].
int _fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash *= prime; // wraps at 64 bits, as FNV expects
  }
  return hash;
}

/// Files written by the previous downloader: `<firestoreId>_<type>.mp3`.
final RegExp _legacyName = RegExp(
  r'^[A-Za-z0-9]{20}_(littleKids|olderKids|grownUps|english|urdu)\.mp3$',
);

bool isLegacyAudioFile(String fileName) => _legacyName.hasMatch(fileName);
