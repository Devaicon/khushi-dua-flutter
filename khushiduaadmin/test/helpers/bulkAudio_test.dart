import 'package:flutter_test/flutter_test.dart';
import 'package:khushiduaadmin/helpers/bulkAudio.dart';
import 'package:khushiduaadmin/models/audioSlot.dart';

const id = '0tgKka3QG4SmpwiCyVfV';
bool exists(String duaId) => duaId == id;

void main() {
  test('reads the dua and recording from the file name', () {
    final m = matchAudioFile('${id}_english.mp3', exists);
    expect(m.ok, isTrue);
    expect(m.duaId, id);
    expect(m.slot, AudioSlot.english);
  });

  test('accepts other separators, cases and short names', () {
    expect(matchAudioFile('$id-GrownUps.mp3', exists).slot, AudioSlot.grownUps);
    expect(matchAudioFile('$id little kids.mp3', exists).slot,
        AudioSlot.littleKids);
    expect(matchAudioFile('${id}_ur.m4a', exists).slot, AudioSlot.urdu);
  });

  test('explains a name it cannot read', () {
    expect(matchAudioFile('recording.mp3', exists).problem, contains('Name it'));
    expect(matchAudioFile('${id}_french.mp3', exists).problem,
        contains('not a recording'));
    expect(matchAudioFile('AAAAAAAAAAAAAAAAAAAA_english.mp3', exists).problem,
        contains('No dua'));
  });

  test('flags a second file for the same recording', () {
    final matches = matchAudioFiles(
        ['${id}_english.mp3', '${id}_en.mp3', '${id}_urdu.mp3'], exists);
    expect(matches.map((m) => m.ok), [true, false, true]);
  });

  test('names a download so bulk upload reads it back', () {
    for (final slot in AudioSlot.values) {
      final name = audioDownloadName(id, slot, 'audio/mpeg');
      expect(name, '${id}_${slot.name}.mp3');
      expect(matchAudioFile(name, exists).slot, slot);
    }
    expect(audioDownloadName(id, AudioSlot.urdu, 'audio/x-m4a'),
        '${id}_urdu.m4a');
    expect(audioDownloadName(id, AudioSlot.urdu, ''), '${id}_urdu.mp3');
  });
}
