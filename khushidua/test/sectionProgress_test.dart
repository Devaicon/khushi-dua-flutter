import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/sectionProgress.dart';
import 'package:khushidua/models/duaModel.dart';

DuaModel dua(
  String id,
  List<String> subCategoryIds, {
  bool isEnabled = true,
  bool littleKids = true,
  bool olderKids = true,
  bool grownUps = true,
}) => DuaModel.fromMap({
  'id': id,
  'subCategoryIds': subCategoryIds,
  'isEnabled': isEnabled,
  'littleKids': littleKids,
  'olderKids': olderKids,
  'grownUps': grownUps,
});

void main() {
  group('isDuaShownFor', () {
    test('hides disabled duas', () {
      expect(isDuaShownFor(dua('d', [], isEnabled: false), 2), isFalse);
    });

    test('honours each age group flag', () {
      final grownUpsOnly = dua('d', [], littleKids: false, olderKids: false);
      expect(isDuaShownFor(grownUpsOnly, 0), isFalse);
      expect(isDuaShownFor(grownUpsOnly, 1), isFalse);
      expect(isDuaShownFor(grownUpsOnly, 2), isTrue);
    });
  });

  group('isSectionComplete', () {
    test('needs every visible dua listened', () {
      final duas = [dua('a', ['s']), dua('b', ['s'])];
      expect(isSectionComplete('s', duas, {'a'}, 2), isFalse);
      expect(isSectionComplete('s', duas, {'a', 'b'}, 2), isTrue);
    });

    test('ignores disabled duas, which the reader can never open', () {
      final duas = [dua('a', ['s']), dua('hidden', ['s'], isEnabled: false)];
      expect(isSectionComplete('s', duas, {'a'}, 2), isTrue);
    });

    test('ignores duas for other age groups', () {
      final duas = [
        dua('kids', ['s'], grownUps: false),
        dua('adults', ['s'], littleKids: false, olderKids: false),
      ];
      expect(isSectionComplete('s', duas, {'kids'}, 0), isTrue);
      expect(isSectionComplete('s', duas, {'kids'}, 2), isFalse);
    });

    test('a section with nothing to listen to is not complete', () {
      expect(isSectionComplete('s', [dua('a', ['other'])], {'a'}, 2), isFalse);
    });
  });

  group('SectionProgress', () {
    // Four sections, so the first two are free and the last two are locked.
    final sections = ['s1', 's2', 's3', 's4'];
    final duas = [
      dua('a', ['s1']),
      dua('b', ['s2']),
      dua('c', ['s3']),
      dua('d', ['s4']),
    ];

    SectionProgress progress(Set<String> read, {bool restricted = true}) =>
        SectionProgress.compute(
          sectionIds: sections,
          allDuas: duas,
          listenedDuaIds: read,
          ageGroup: 2,
          restricted: restricted,
        );

    test('the first half is always open', () {
      final p = progress({});
      expect([for (var i = 0; i < 4; i++) p.isUnlocked(i)], [
        true,
        true,
        false,
        false,
      ]);
      expect(p.freeSectionCount, 2);
      expect(p.completedFreeSections, 0);
    });

    test('finishing the first half unlocks the rest', () {
      expect(progress({'a'}).isUnlocked(2), isFalse);
      final p = progress({'a', 'b'});
      expect(p.completedFreeSections, 2);
      expect(p.isUnlocked(2), isTrue);
      expect(p.isUnlocked(3), isTrue);
    });

    test('members and guests are never restricted', () {
      expect(progress({}, restricted: false).isUnlocked(3), isTrue);
    });

    test('an odd count gives the extra section to the free half', () {
      final p = SectionProgress.compute(
        sectionIds: ['s1', 's2', 's3'],
        allDuas: duas,
        listenedDuaIds: {},
        ageGroup: 2,
        restricted: true,
      );
      expect(p.freeSectionCount, 2);
      expect(p.isUnlocked(1), isTrue);
      expect(p.isUnlocked(2), isFalse);
    });
  });
}
