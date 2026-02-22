class SubCategoryModel {
  String id = '';
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
  String categoryId = "";
  bool littleKids = true;
  bool olderKids = true;
  bool grownUps = true;
  String image = "";

  SubCategoryModel({
    required this.id,
    required this.image,
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
    required this.categoryId,
    required this.grownUps,
    required this.littleKids,
    required this.olderKids,
  });

  factory SubCategoryModel.fromMap(Map<String, dynamic> map) {
    return SubCategoryModel(
        id: map["id"] ?? '',
        createdAt: map["createdAt"] != null
            ? map["createdAt"].toDate()
            : DateTime.now(),
        updatedAt: map["updatedAt"] != null
            ? map["updatedAt"].toDate()
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
        urdu: map["urdu"] ?? '',
        order: map["order"] ?? 0,
        littleKids: map["littleKids"] ?? true,
        olderKids: map["olderKids"] ?? true,
        grownUps: map["grownUps"] ?? true,
        categoryId: map["categoryId"] ?? '',
        image: map["image"]);
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
      "categoryId": categoryId,
      "image": image,
    };
  }
}
