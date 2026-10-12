import '../constants/languages.dart';
import 'audioSlot.dart';
import 'modelValues.dart';

class DuaModel {
  String id = '';
  String arabic = '';
  String bengali = '';
  String transliteration = '';
  String english = '';
  String french = '';
  String german = '';
  String gujrati = '';
  String hindi = '';
  String indonesian = '';
  String japanese = '';
  String malay = '';
  String mandrain = '';
  String marathi = '';
  String portugese = '';
  String punjabi = '';
  String russian = '';
  String sindhi = '';
  String spanish = '';
  String tamil = '';
  String telgu = '';
  String turkish = '';
  String urdu = '';
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  bool isEnabled = true;
  int order = 0;
  bool littleKids = true;
  bool olderKids = true;
  bool grownUps = true;
  List<String> subCategoryIds = [];
  String littleKidsAudio = "";
  String olderKidsAudio = "";
  String grownUpsAudio = "";
  String? englishTranslation = "";
  String? urduTranslation = '';
  String? benefits; // Benefits data - simple string field
  String? description; // Description field

  DuaModel(
      {required this.id,
      required this.createdAt,
      required this.arabic,
      required this.bengali,
      required this.transliteration,
      required this.english,
      required this.french,
      required this.german,
      required this.gujrati,
      required this.hindi,
      required this.indonesian,
      required this.isEnabled,
      required this.japanese,
      required this.subCategoryIds,
      required this.malay,
      required this.mandrain,
      required this.marathi,
      required this.portugese,
      required this.punjabi,
      required this.russian,
      required this.sindhi,
      required this.spanish,
      required this.tamil,
      required this.telgu,
      required this.turkish,
      required this.updatedAt,
      required this.urdu,
      required this.order,
      required this.grownUps,
      required this.littleKids,
      required this.olderKids,
      required this.grownUpsAudio,
      required this.littleKidsAudio,
      required this.olderKidsAudio,
      this.englishTranslation,
      this.urduTranslation,
      this.benefits,
      this.description});

  /// A blank dua, as the editor starts one.
  factory DuaModel.empty() => DuaModel.fromMap(const {});

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    return DuaModel(
      id: readString(map["id"]),
      createdAt: readDate(map["createdAt"]),
      arabic: readString(map["arabic"]),
      transliteration: readString(map["transliteration"]),
      bengali: readString(map["bengali"]),
      english: readString(map["english"]),
      french: readString(map["french"]),
      german: readString(map["german"]),
      gujrati: readString(map["gujrati"]),
      hindi: readString(map["hindi"]),
      indonesian: readString(map["indonesian"]),
      isEnabled: readBool(map["isEnabled"]),
      japanese: readString(map["japanese"]),
      subCategoryIds: readStringList(map["subCategoryIds"]),
      malay: readString(map["malay"]),
      mandrain: readString(map["mandrain"]),
      marathi: readString(map["marathi"]),
      portugese: readString(map["portugese"]),
      punjabi: readString(map["punjabi"]),
      russian: readString(map["russian"]),
      sindhi: readString(map["sindhi"]),
      spanish: readString(map["spanish"]),
      tamil: readString(map["tamil"]),
      telgu: readString(map["telgu"]),
      turkish: readString(map["turkish"]),
      updatedAt: readDate(map["updatedAt"]),
      urdu: readString(map["urdu"]),
      order: readInt(map["order"]),
      littleKids: readBool(map["littleKids"]),
      olderKids: readBool(map["olderKids"]),
      grownUps: readBool(map["grownUps"]),
      littleKidsAudio: readString(map["littleKidsAudio"]),
      olderKidsAudio: readString(map["olderKidsAudio"]),
      grownUpsAudio: readString(map["grownUpsAudio"]),
      englishTranslation: readString(map["englishTranslation"]),
      urduTranslation: readString(map["urduTranslation"]),
      benefits: map["benefits"] == null
          ? null
          : (map["benefits"] is String
              ? map["benefits"]
              : map["benefits"].toString()),
      description: readString(map["description"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "createdAt": createdAt,
      "arabic": arabic,
      "bengali": bengali,
      "transliteration": transliteration,
      "english": english,
      "french": french,
      "german": german,
      "gujrati": gujrati,
      "hindi": hindi,
      "indonesian": indonesian,
      "isEnabled": isEnabled,
      "japanese": japanese,
      "subCategoryIds": subCategoryIds,
      "malay": malay,
      "mandrain": mandrain,
      "marathi": marathi,
      "portugese": portugese,
      "punjabi": punjabi,
      "russian": russian,
      "sindhi": sindhi,
      "spanish": spanish,
      "tamil": tamil,
      "telgu": telgu,
      "turkish": turkish,
      "updatedAt": updatedAt,
      "urdu": urdu,
      "order": order,
      "grownUps": grownUps,
      "olderKids": olderKids,
      "littleKids": littleKids,
      "grownUpsAudio": grownUpsAudio,
      "littleKidsAudio": littleKidsAudio,
      "olderKidsAudio": olderKidsAudio,
      "englishTranslation": englishTranslation,
      "urduTranslation": urduTranslation,
      "benefits": benefits,
      "description": description,
    };
  }

  /// An independent copy, for editing without touching the live list.
  DuaModel copy() =>
      DuaModel.fromMap(toMap())..subCategoryIds = [...subCategoryIds];

  /// The text in the language stored under [field] (see `kContentLanguages`).
  String text(String field) => readString(toMap()[field]);

  void setText(String field, String value) {
    switch (field) {
      case 'arabic':
        arabic = value;
      case 'transliteration':
        transliteration = value;
      case 'english':
        english = value;
      case 'urdu':
        urdu = value;
      case 'bengali':
        bengali = value;
      case 'french':
        french = value;
      case 'german':
        german = value;
      case 'gujrati':
        gujrati = value;
      case 'hindi':
        hindi = value;
      case 'indonesian':
        indonesian = value;
      case 'japanese':
        japanese = value;
      case 'malay':
        malay = value;
      case 'mandrain':
        mandrain = value;
      case 'marathi':
        marathi = value;
      case 'portugese':
        portugese = value;
      case 'punjabi':
        punjabi = value;
      case 'russian':
        russian = value;
      case 'sindhi':
        sindhi = value;
      case 'spanish':
        spanish = value;
      case 'tamil':
        tamil = value;
      case 'telgu':
        telgu = value;
      case 'turkish':
        turkish = value;
      default:
        throw ArgumentError.value(field, 'field', 'not a dua language');
    }
  }

  String audio(AudioSlot slot) => switch (slot) {
        AudioSlot.littleKids => littleKidsAudio,
        AudioSlot.olderKids => olderKidsAudio,
        AudioSlot.grownUps => grownUpsAudio,
        AudioSlot.english => englishTranslation ?? '',
        AudioSlot.urdu => urduTranslation ?? '',
      };

  void setAudio(AudioSlot slot, String url) {
    switch (slot) {
      case AudioSlot.littleKids:
        littleKidsAudio = url;
      case AudioSlot.olderKids:
        olderKidsAudio = url;
      case AudioSlot.grownUps:
        grownUpsAudio = url;
      case AudioSlot.english:
        englishTranslation = url;
      case AudioSlot.urdu:
        urduTranslation = url;
    }
  }

  bool hasAudio(AudioSlot slot) => audio(slot).isNotEmpty;

  bool shownTo(AgeGroup group) => switch (group) {
        AgeGroup.littleKids => littleKids,
        AgeGroup.olderKids => olderKids,
        AgeGroup.grownUps => grownUps,
      };

  void setShownTo(AgeGroup group, bool shown) {
    switch (group) {
      case AgeGroup.littleKids:
        littleKids = shown;
      case AgeGroup.olderKids:
        olderKids = shown;
      case AgeGroup.grownUps:
        grownUps = shown;
    }
  }

  /// The recitation the app plays for [group]; an age group without its
  /// own recording plays nothing.
  String recitationFor(AgeGroup group) => switch (group) {
        AgeGroup.littleKids => littleKidsAudio,
        AgeGroup.olderKids => olderKidsAudio,
        AgeGroup.grownUps => grownUpsAudio,
      };

  /// The recordings missing for the age groups this dua is shown to, plus
  /// any missing translation.
  List<AudioSlot> get missingAudio => [
        for (final slot in AudioSlot.values)
          if (!hasAudio(slot) &&
              (!slot.isRecitation ||
                  shownTo(AgeGroup.values[slot.index])))
            slot,
      ];

  /// The age groups that see this dua but have no recitation to hear: their
  /// Listen button is greyed out in the app.
  List<AudioSlot> get missingRecitations =>
      [for (final s in missingAudio) if (s.isRecitation) s];

  /// Translations filled in, out of [kTranslationLanguages].
  int get translationCount =>
      kTranslationLanguages.where((l) => text(l.field).trim().isNotEmpty).length;

  /// A one-line name for lists: English, else the start of the Arabic.
  String get title {
    if (english.trim().isNotEmpty) return english.trim();
    if (arabic.trim().isNotEmpty) return arabic.trim();
    return '(untitled dua)';
  }
}
