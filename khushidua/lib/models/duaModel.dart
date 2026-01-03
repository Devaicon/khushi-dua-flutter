import 'package:flutter/foundation.dart';

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
  List<Map<String, dynamic>>? benefits; // Benefits data (List format)
  String? benefitsString; // Benefits data (String format)

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
    this.benefitsString,
  });

  /// Safely parses benefits field which might be a List, String, or null
  static List<Map<String, dynamic>>? _parseBenefitsList(dynamic benefits) {
    debugPrint('_parseBenefitsList called with: $benefits');
    debugPrint('  Type: ${benefits?.runtimeType}');

    if (benefits == null) {
      debugPrint('  Result: null (benefits is null)');
      return null;
    }

    // If it's already a List
    if (benefits is List) {
      try {
        var result = benefits
            .map(
              (item) => item is Map<String, dynamic>
                  ? item
                  : item is Map
                  ? Map<String, dynamic>.from(item)
                  : {},
            )
            .toList()
            .cast<Map<String, dynamic>>();
        debugPrint('  Result: List with ${result.length} items');
        return result;
      } catch (e) {
        debugPrint('  Result: null (conversion failed: $e)');
        return null;
      }
    }

    // If it's a String, return null (we'll handle it separately)
    if (benefits is String) {
      debugPrint('  Result: null (benefits is String, handled separately)');
      return null;
    }

    // For any other type, return null
    debugPrint('  Result: null (unknown type)');
    return null;
  }

  /// Safely parses benefits field as String
  static String? _parseBenefitsString(dynamic benefits) {
    debugPrint('_parseBenefitsString called with: $benefits');
    debugPrint('  Type: ${benefits?.runtimeType}');

    if (benefits == null) {
      debugPrint('  Result: null (benefits is null)');
      return null;
    }

    // If it's a String, return it
    if (benefits is String) {
      var trimmed = benefits.trim();
      var result = trimmed.isEmpty ? null : benefits;
      debugPrint('  Result: ${result ?? "null (empty string)"}');
      return result;
    }

    // For any other type, return null
    debugPrint('  Result: null (not a String)');
    return null;
  }

  // Debug method to debugPrint benefits data
  DuaModel _debugPrintBenefits() {
    return this;
  }

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    final dua = DuaModel(
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
      grownUps: map["grownUps"],
      littleKidsAudio: map["littleKidsAudio"],
      olderKidsAudio: map["olderKidsAudio"],
      grownUpsAudio: map["grownUpsAudio"],
      englishTranslation: map["englishTranslation"],
      urduTranslation: map["urduTranslation"],
      benefits: _parseBenefitsList(map["benefits"]),
      benefitsString: _parseBenefitsString(map["benefits"]),
    );

    dua._debugPrintBenefits();
    return dua;
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
      "order": order,
      "grownUps": grownUps,
      "olderKids": olderKids,
      "littleKids": littleKids,
      "grownUpsAudio": grownUpsAudio,
      "littleKidsAudio": littleKidsAudio,
      "olderKidsAudio": olderKidsAudio,
      "englishTranslation": englishTranslation,
      "urduTranslation": urduTranslation,
      "benefits": benefits ?? benefitsString,
    };
  }

  // Get benefit text based on language
  // For List format: returns specific language from the map at index
  // For String format: returns the string directly (ignoring index and language)
  String? getBenefitText(int index, String languageCode) {
    // If benefits is a String, return it directly
    if (benefitsString != null && benefitsString!.isNotEmpty) {
      return benefitsString;
    }

    // Otherwise, handle List format
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

  // Check if benefits exist (either as String or List)
  bool hasBenefits() {
    bool hasString = benefitsString != null && benefitsString!.isNotEmpty;
    bool hasList = benefits != null && benefits!.isNotEmpty;
    return hasString || hasList;
  }

  // Get benefits count (1 for string, length for list)
  int getBenefitsCount() {
    if (benefitsString != null && benefitsString!.isNotEmpty) {
      return 1;
    }
    if (benefits != null && benefits!.isNotEmpty) {
      return benefits!.length;
    }
    return 0;
  }
}
