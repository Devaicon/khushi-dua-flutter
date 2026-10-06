import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/audioFiles.dart';

void main() {
  const url =
      'https://firebasestorage.googleapis.com/v0/b/khushidua.firebasestorage.app/o/Mu7mo3g5AjSbxDzwBmmn%2FgrownUpsAudio?alt=media&token=9d289597';

  group('audioFileNameFor', () {
    test('is the same every time for the same URL', () {
      expect(audioFileNameFor(url), audioFileNameFor(url));
    });

    test('is a fixed-width mp3 name', () {
      expect(
        audioFileNameFor(url),
        matches(RegExp(r'^audio_[0-9a-f]{16}\.mp3$')),
      );
    });

    test('changes when the admin re-uploads (new token)', () {
      expect(
        audioFileNameFor(url),
        isNot(audioFileNameFor(url.replaceFirst('9d289597', '1a2b3c4d'))),
      );
    });

    test('differs between the recordings of one dua', () {
      expect(
        audioFileNameFor(url),
        isNot(audioFileNameFor(url.replaceFirst('grownUps', 'olderKids'))),
      );
    });
  });

  group('isLegacyAudioFile', () {
    test('matches the old <id>_<type>.mp3 names', () {
      expect(isLegacyAudioFile('Mu7mo3g5AjSbxDzwBmmn_grownUps.mp3'), isTrue);
      expect(isLegacyAudioFile('Mu7mo3g5AjSbxDzwBmmn_english.mp3'), isTrue);
    });

    test('leaves other files alone', () {
      expect(isLegacyAudioFile(audioFileNameFor(url)), isFalse);
      expect(isLegacyAudioFile('recording.mp3'), isFalse);
      expect(isLegacyAudioFile('Mu7mo3g5AjSbxDzwBmmn_grownUps.m4a'), isFalse);
    });
  });
}
