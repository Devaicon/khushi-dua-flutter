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
}
