// Reports which Firestore documents still need translating.
//
// Category, subcategory and dua names live in Firestore with one field per
// language. When a field is blank, or holds the English text verbatim, the app
// shows English no matter which language the user picked — and no amount of
// app-side work fixes it. This script turns that into a checklist for whoever
// fills the admin panel.
//
// Read-only: it never writes to Firestore.
//
//   dart run tool/audit_translations.dart [--out report.csv]
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:khushidua/firebase_options.dart';

/// The per-language field names as they are spelled in Firestore. Several are
/// misspelled there ("gujrati", "mandrain", "portugese", "telgu"); the app
/// reads those spellings, so the audit must use them too.
const List<String> _languageFields = [
  'arabic', 'bengali', 'french', 'german', 'gujrati', 'hindi', 'indonesian',
  'japanese', 'malay', 'mandrain', 'marathi', 'portugese', 'punjabi',
  'russian', 'sindhi', 'spanish', 'tamil', 'telgu', 'turkish', 'urdu',
];

const List<String> _collections = ['categories', 'subCategories', 'duas'];

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final outIndex = args.indexOf('--out');
  final outPath = outIndex != -1 && outIndex + 1 < args.length
      ? args[outIndex + 1]
      : 'translation-audit.csv';

  final rows = <List<String>>[
    ['collection', 'documentId', 'english', 'issue', 'fields'],
  ];
  var clean = 0;

  for (final collection in _collections) {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .get();
    stdout.writeln('$collection: ${snapshot.docs.length} documents');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final english = (data['english'] as String? ?? '').trim();

      final empty = <String>[];
      final sameAsEnglish = <String>[];

      for (final field in _languageFields) {
        final value = (data[field] as String? ?? '').trim();
        if (value.isEmpty) {
          empty.add(field);
        } else if (english.isNotEmpty &&
            value.toLowerCase() == english.toLowerCase()) {
          // Untranslated text copied across, which is what makes a category
          // like "Protection from Dajjal" stay English in every language.
          sameAsEnglish.add(field);
        }
      }

      if (empty.isEmpty && sameAsEnglish.isEmpty) {
        clean++;
        continue;
      }
      if (empty.isNotEmpty) {
        rows.add([collection, doc.id, english, 'empty', empty.join(' ')]);
      }
      if (sameAsEnglish.isNotEmpty) {
        rows.add([
          collection,
          doc.id,
          english,
          'same as english',
          sameAsEnglish.join(' '),
        ]);
      }
    }
  }

  await File(outPath).writeAsString(rows.map(_csvLine).join('\n'));

  stdout
    ..writeln('')
    ..writeln('$clean documents fully translated')
    ..writeln('${rows.length - 1} issues written to $outPath');
  exit(0);
}

String _csvLine(List<String> cells) => cells.map(_csvCell).join(',');

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
