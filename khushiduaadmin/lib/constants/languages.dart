/// The languages content is written in, by Firestore field name.
///
/// Field names keep the spellings already stored in Firestore
/// (`gujrati`, `mandrain`, `portugese`, `telgu`); the labels are spelt
/// properly. Pure Dart, so it can be unit tested.
library;

class ContentLanguage {
  const ContentLanguage(this.field, this.label, {this.rtl = false});

  /// The Firestore field that holds this language.
  final String field;
  final String label;

  /// Right-to-left script.
  final bool rtl;
}

/// Arabic and English first: they are required. Then Urdu, the app's other
/// main language, then the rest alphabetically.
const List<ContentLanguage> kContentLanguages = [
  ContentLanguage('arabic', 'Arabic', rtl: true),
  ContentLanguage('english', 'English'),
  ContentLanguage('urdu', 'Urdu', rtl: true),
  ContentLanguage('bengali', 'Bengali'),
  ContentLanguage('french', 'French'),
  ContentLanguage('german', 'German'),
  ContentLanguage('gujrati', 'Gujarati'),
  ContentLanguage('hindi', 'Hindi'),
  ContentLanguage('indonesian', 'Indonesian'),
  ContentLanguage('japanese', 'Japanese'),
  ContentLanguage('malay', 'Malay'),
  ContentLanguage('mandrain', 'Mandarin'),
  ContentLanguage('marathi', 'Marathi'),
  ContentLanguage('portugese', 'Portuguese'),
  ContentLanguage('punjabi', 'Punjabi'),
  ContentLanguage('russian', 'Russian'),
  ContentLanguage('sindhi', 'Sindhi', rtl: true),
  ContentLanguage('spanish', 'Spanish'),
  ContentLanguage('tamil', 'Tamil'),
  ContentLanguage('telgu', 'Telugu'),
  ContentLanguage('turkish', 'Turkish'),
];

/// Every language but Arabic, which for a dua is the text itself rather
/// than a translation of it.
List<ContentLanguage> get kTranslationLanguages =>
    kContentLanguages.where((l) => l.field != 'arabic').toList();

/// The age groups, in the app's order (0 little kids, 1 older kids,
/// 2 grown-ups), with the Firestore flag that shows content to each.
enum AgeGroup {
  littleKids('littleKids', 'Little Kids'),
  olderKids('olderKids', 'Older Kids'),
  grownUps('grownUps', 'Grown-ups');

  const AgeGroup(this.field, this.label);
  final String field;
  final String label;
}
