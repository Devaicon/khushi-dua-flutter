
class DuaModel{
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
  int order=0;
  bool littleKids=true;
  bool olderKids=true;
  bool grownUps=true;
  List<String> subCategoryIds=[];
  String littleKidsAudio="";
  String olderKidsAudio="";
  String grownUpsAudio="";
  String? englishTranslation="";
  String? urduTranslation='';
  String? benefits; // Benefits data - simple string field
  String? description; // Description field


  DuaModel({
    required this.id,
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
    this.description
  });

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    return DuaModel(
        id: map["id"],
        createdAt: map["createdAt"].toDate(),
        arabic: map["arabic"],
        transliteration: map["transliteration"],
        bengali: map["bengali"],
        english: map["english"],
        french: map["french"],
        german: map["german"],
        gujrati: map["gujrati"],
        hindi: map["hindi"],
        indonesian: map["indonesian"],
        isEnabled: map["isEnabled"],
        japanese: map["japanese"],
        subCategoryIds: List<String>.from(map["subCategoryIds"] ?? []),
        malay: map["malay"],
        mandrain: map["mandrain"],
        marathi: map["marathi"],
        portugese: map["portugese"],
        punjabi: map["punjabi"],
        russian: map["russian"],
        sindhi: map["sindhi"],
        spanish: map["spanish"],
        tamil: map["tamil"],
        telgu: map["telgu"],
        turkish: map["turkish"],
        updatedAt: map["updatedAt"].toDate(),
        urdu: map["urdu"],
        order: map["order"],
        littleKids: map["littleKids"],
        olderKids: map["olderKids"],
        grownUps:map["grownUps"],
      littleKidsAudio: map["littleKidsAudio"] ?? "",
      olderKidsAudio: map["olderKidsAudio"] ?? "",
      grownUpsAudio: map["grownUpsAudio"] ?? "",
      englishTranslation: map["englishTranslation"],
      urduTranslation: map["urduTranslation"],
      benefits: map["benefits"] != null ? (map["benefits"] is String ? map["benefits"] : map["benefits"].toString()) : null,
      description: map["description"],
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
      "order":order,
      "grownUps":grownUps,
      "olderKids":olderKids,
      "littleKids":littleKids,
      "grownUpsAudio":grownUpsAudio,
      "littleKidsAudio":littleKidsAudio,
      "olderKidsAudio":olderKidsAudio,
      "englishTranslation":englishTranslation,
      "urduTranslation":urduTranslation,
      "benefits": benefits,
      "description": description,
    };
  }

}