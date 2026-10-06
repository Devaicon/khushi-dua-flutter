import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/helpers/duaNumberSearch.dart';

void main() {
  test('a bare number, with or without # or "dua"', () {
    for (final q in ['3', '#3', 'dua 3', 'Dua #3', ' 3 ']) {
      final parsed = DuaNumberQuery.parse(q)!;
      expect(parsed.number, 3, reason: q);
      expect(parsed.text, '', reason: q);
    }
  });

  test('a section name with a number, either way round', () {
    for (final q in ['morning 3', '3 morning', 'Morning dua 3']) {
      final parsed = DuaNumberQuery.parse(q)!;
      expect(parsed.number, 3, reason: q);
      expect(parsed.text, 'morning', reason: q);
    }
  });

  test('the last number is the dua; earlier ones stay in the name', () {
    final parsed = DuaNumberQuery.parse('99 names 2')!;
    expect(parsed.number, 2);
    expect(parsed.text, '99 names');
  });

  test('no number, or zero, is not a number search', () {
    expect(DuaNumberQuery.parse('morning'), isNull);
    expect(DuaNumberQuery.parse(''), isNull);
    expect(DuaNumberQuery.parse('0'), isNull);
  });
}
