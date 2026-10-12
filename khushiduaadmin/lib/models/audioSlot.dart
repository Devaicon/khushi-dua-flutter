/// The five recordings a dua can carry.
///
/// Pure Dart, so the bulk-upload matcher can be unit tested.
library;

enum AudioSlot {
  littleKids('littleKidsAudio', 'Little Kids', 'littleKidsAudio'),
  olderKids('olderKidsAudio', 'Older Kids', 'olderKidsAudio'),
  grownUps('grownUpsAudio', 'Grown-ups', 'grownUpsAudio'),
  english('englishTranslation', 'English translation', 'englishTransAudio'),
  urdu('urduTranslation', 'Urdu translation', 'urduTransAudio');

  const AudioSlot(this.field, this.label, this.storageName);

  /// The dua document field holding the download URL.
  final String field;
  final String label;

  /// The file name under `<duaId>/` in Storage. Existing recordings use
  /// these names, so a replacement overwrites the old file.
  final String storageName;

  /// The recitations, one per age group, as opposed to translations.
  bool get isRecitation =>
      this == littleKids || this == olderKids || this == grownUps;

  String get shortLabel => switch (this) {
        littleKids => 'Little',
        olderKids => 'Older',
        grownUps => 'Grown',
        english => 'EN',
        urdu => 'UR',
      };
}
