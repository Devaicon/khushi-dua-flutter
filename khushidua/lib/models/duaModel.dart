
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
  List<Map<String, dynamic>>? benefits; // Benefits data


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
      this.benefits
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
      littleKidsAudio: map["littleKidsAudio"],
      olderKidsAudio: map["olderKidsAudio"],
      grownUpsAudio: map["grownUpsAudio"],
      englishTranslation: map["englishTranslation"],
      urduTranslation: map["urduTranslation"],
      benefits: map["benefits"] != null 
          ? List<Map<String, dynamic>>.from(map["benefits"] ?? [])
          : null,
    );
  }

  String getName(String languageCode) {
    switch (languageCode) {
      case 'Arabic':
        return arabic;
      case 'Bengali':
        return bengali;
      case 'English':
        return english;
      case 'French':
        return french;
      case 'German':
        return german;
      case 'Gujarati':
        return gujrati;
      case 'Hindi':
        return hindi;
      case 'Indonesian':
        return indonesian;
      case 'Japanese':
        return japanese;
      case 'Malay':
        return malay;
      case 'Mandarin':
        return mandrain;
      case 'Marathi':
        return marathi;
      case 'Portuguese':
        return portugese;
      case 'Punjabi':
        return punjabi;
      case 'Russian':
        return russian;
      case 'Sindhi':
        return sindhi;
      case 'Spanish':
        return spanish;
      case 'Tamil':
        return tamil;
      case 'Telugu':
        return telgu;
      case 'Turkish':
        return turkish;
      case 'Urdu':
        return urdu;
      default:
        return english; // fallback
    }
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
    };
  }

  // Get benefit text based on language
  String? getBenefitText(int index, String languageCode) {
    if (benefits == null || index >= benefits!.length) return null;
    
    final benefit = benefits![index];
    switch (languageCode) {
      case 'English':
        return benefit['english'] as String?;
      case 'Urdu':
        return benefit['urdu'] as String?;
      case 'Arabic':
        return benefit['arabicText'] as String?;
      case 'Punjabi':
        return benefit['punjabi'] as String?;
      case 'Bengali':
        return benefit['bengali'] as String?;
      case 'Gujarati':
        return benefit['gujarati'] as String?;
      case 'Telugu':
        return benefit['telugu'] as String?;
      case 'Russian':
        return benefit['russian'] as String?;
      case 'Mandarin':
        return benefit['mandarin'] as String?;
      default:
        return benefit['english'] as String?;
    }
  }

  // Check if benefits exist
  bool hasBenefits() {
    return benefits != null && benefits!.isNotEmpty;
  }

}