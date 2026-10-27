/// Matches audio files to duas by file name, for bulk upload.
///
/// A file is named after the dua's id and the recording it is:
/// `<duaId>_<slot>.mp3`, e.g. `0tgKka3QG4SmpwiCyVfV_english.mp3`. A hyphen or
/// space works in place of the underscore. Pure Dart, so it can be unit
/// tested.
library;

import '../models/audioSlot.dart';

/// Words accepted for each slot, lowercase with separators removed.
const Map<String, AudioSlot> kSlotNames = {
  'littlekids': AudioSlot.littleKids,
  'littlekid': AudioSlot.littleKids,
  'little': AudioSlot.littleKids,
  'olderkids': AudioSlot.olderKids,
  'olderkid': AudioSlot.olderKids,
  'older': AudioSlot.olderKids,
  'grownups': AudioSlot.grownUps,
  'grownup': AudioSlot.grownUps,
  'grown': AudioSlot.grownUps,
  'adults': AudioSlot.grownUps,
  'english': AudioSlot.english,
  'en': AudioSlot.english,
  'englishtranslation': AudioSlot.english,
  'urdu': AudioSlot.urdu,
  'ur': AudioSlot.urdu,
  'urdutranslation': AudioSlot.urdu,
};

final RegExp _fileName =
    RegExp(r'^([A-Za-z0-9]{20})[ _-]+([A-Za-z _-]+)\.(mp3|m4a|wav|aac|ogg)$');

/// What a file name says, or why it says nothing usable.
class AudioFileMatch {
  const AudioFileMatch._(this.fileName, this.duaId, this.slot, this.problem);

  final String fileName;
  final String? duaId;
  final AudioSlot? slot;

  /// Why the file cannot be used; null when it can.
  final String? problem;

  bool get ok => problem == null;
}

/// Reads [fileName]. [duaExists] says whether an id belongs to a dua.
AudioFileMatch matchAudioFile(
  String fileName,
  bool Function(String duaId) duaExists,
) {
  final m = _fileName.firstMatch(fileName.trim());
  if (m == null) {
    return AudioFileMatch._(fileName, null, null,
        'Name it <dua id>_<recording>.mp3, e.g. <id>_english.mp3');
  }
  final id = m.group(1)!;
  final slotWord = m.group(2)!.toLowerCase().replaceAll(RegExp(r'[ _-]'), '');
  final slot = kSlotNames[slotWord];
  if (slot == null) {
    return AudioFileMatch._(fileName, id, null,
        '"${m.group(2)}" is not a recording: use littleKids, olderKids, grownUps, english or urdu');
  }
  if (!duaExists(id)) {
    return AudioFileMatch._(fileName, id, slot, 'No dua has the id $id');
  }
  return AudioFileMatch._(fileName, id, slot, null);
}

/// Reads every name, and flags a second file for the same dua and recording
/// so one does not silently overwrite the other.
List<AudioFileMatch> matchAudioFiles(
  List<String> fileNames,
  bool Function(String duaId) duaExists,
) {
  final seen = <String>{};
  return [
    for (final name in fileNames)
      () {
        final match = matchAudioFile(name, duaExists);
        if (!match.ok) return match;
        final key = '${match.duaId}/${match.slot!.name}';
        if (!seen.add(key)) {
          return AudioFileMatch._(name, match.duaId, match.slot,
              'Another file is already going to ${match.slot!.label} of this dua');
        }
        return match;
      }(),
  ];
}

/// The name a downloaded recording is saved under: the same
/// `<duaId>_<slot>.<ext>` form bulk upload reads, so a downloaded file can go
/// back up unchanged. [contentType] picks the extension; Storage objects are
/// named without one.
String audioDownloadName(String duaId, AudioSlot slot, String contentType) {
  final ext = switch (contentType.split(';').first.trim().toLowerCase()) {
    'audio/mp4' || 'audio/x-m4a' || 'audio/m4a' => 'm4a',
    'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
    'audio/aac' => 'aac',
    'audio/ogg' => 'ogg',
    _ => 'mp3',
  };
  return '${duaId}_${slot.name}.$ext';
}
