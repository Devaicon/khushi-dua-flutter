import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khushidua/constants/translations.dart';

/// Guards the translation map against the two ways it has silently regressed
/// before: a key added to English but not to the other languages, and a `.tr`
/// call site whose key was never added to the map at all. Both render English
/// text to users who picked another language, with no error anywhere.
void main() {
  final translations = AppTranslations.translations;
  final english = translations['English']!;

  test('every language block defines every English key', () {
    final gaps = <String, List<String>>{};
    for (final entry in translations.entries) {
      if (entry.key == 'English') continue;
      final missing = english.keys
          .where((k) => !entry.value.containsKey(k))
          .toList();
      if (missing.isNotEmpty) gaps[entry.key] = missing;
    }

    expect(
      gaps,
      isEmpty,
      reason:
          'These languages fall back to English for the listed keys:\n'
          '${gaps.entries.map((e) => '  ${e.key}: ${e.value.join(', ')}').join('\n')}',
    );
  });

  test('no translation is blank', () {
    final blanks = <String>[];
    for (final entry in translations.entries) {
      for (final pair in entry.value.entries) {
        if (pair.value.trim().isEmpty) {
          blanks.add('${entry.key}/${pair.key}');
        }
      }
    }
    expect(blanks, isEmpty, reason: 'Blank translations: $blanks');
  });

  test('every language block has the same key count', () {
    final counts = {
      for (final e in translations.entries) e.key: e.value.length,
    };
    expect(counts.values.toSet(), hasLength(1), reason: 'Key counts: $counts');
  });

  test('every ".tr" key in lib/ exists in the English block', () {
    // Matches "Some text".tr and 'Some text'.tr, the two forms used in the app.
    final doubleQuoted = RegExp(r'"((?:[^"\\]|\\.){1,150}?)"\s*\.tr\b');
    final singleQuoted = RegExp(r"'((?:[^'\\]|\\.){1,150}?)'\s*\.tr\b");

    final used = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final re in [doubleQuoted, singleQuoted]) {
        for (final match in re.allMatches(source)) {
          used[match.group(1)!] = entity.path;
        }
      }
    }

    // A non-empty scan proves the regexes still match the codebase; without
    // this the test would pass vacuously if the source layout ever moved.
    expect(used, isNotEmpty, reason: 'Found no ".tr" call sites under lib/');

    final unmapped = used.entries
        .where((e) => !english.containsKey(e.key))
        .map((e) => '${e.key}  (${e.value})')
        .toList();

    expect(
      unmapped,
      isEmpty,
      reason:
          'These keys are translated at the call site but missing from the '
          'map, so they render English in every language:\n'
          '${unmapped.map((u) => '  $u').join('\n')}',
    );
  });
}
