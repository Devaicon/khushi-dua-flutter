class CategoryModel {
  String id = '';
  String logo = '';
  String arabic = '';
  String bengali = '';
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

  CategoryModel(
      {required this.id,
      required this.createdAt,
      required this.arabic,
      required this.bengali,
      required this.english,
      required this.french,
      required this.german,
      required this.gujrati,
      required this.hindi,
      required this.indonesian,
      required this.isEnabled,
      required this.japanese,
      required this.logo,
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
      required this.olderKids});

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
        id: map["id"] ?? '',
        createdAt: map["createdAt"] != null
            ? map["createdAt"].toDate()
            : DateTime.now(),
        arabic: map["arabic"] ?? '',
        bengali: map["bengali"] ?? '',
        english: map["english"] ?? '',
        french: map["french"] ?? '',
        german: map["german"] ?? '',
        gujrati: map["gujrati"] ?? '',
        hindi: map["hindi"] ?? '',
        indonesian: map["indonesian"] ?? '',
        isEnabled: map["isEnabled"] ?? true,
        japanese: map["japanese"] ?? '',
        logo: map["logo"] ?? '',
        malay: map["malay"] ?? '',
        mandrain: map["mandrain"] ?? '',
        marathi: map["marathi"] ?? '',
        portugese: map["portugese"] ?? '',
        punjabi: map["punjabi"] ?? '',
        russian: map["russian"] ?? '',
        sindhi: map["sindhi"] ?? '',
        spanish: map["spanish"] ?? '',
        tamil: map["tamil"] ?? '',
        telgu: map["telgu"] ?? '',
        turkish: map["turkish"] ?? '',
        updatedAt: map["updatedAt"] != null
            ? map["updatedAt"].toDate()
            : DateTime.now(),
        urdu: map["urdu"] ?? '',
        order: map["order"] ?? 0,
        littleKids: map["littleKids"] ?? true,
        olderKids: map["olderKids"] ?? true,
        grownUps: map["grownUps"] ?? true);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "createdAt": createdAt,
      "arabic": arabic,
      "bengali": bengali,
      "english": english,
      "french": french,
      "german": german,
      "gujrati": gujrati,
      "hindi": hindi,
      "indonesian": indonesian,
      "isEnabled": isEnabled,
      "japanese": japanese,
      "logo": logo,
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
      "littleKids": littleKids
    };
  }
}
