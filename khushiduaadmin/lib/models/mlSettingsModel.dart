class MLSettingsModel {
  String id = "";
  String baseUrl = "";
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  MLSettingsModel({
    required this.id,
    required this.baseUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MLSettingsModel.fromMap(Map<String, dynamic> map) {
    return MLSettingsModel(
      id: map["id"] ?? "MemoizationURL",
      // Firebase mein field name "URL" hai, not "baseUrl"
      baseUrl: map["URL"] ?? map["baseUrl"] ?? "",
      createdAt: map["createdAt"] != null ? map["createdAt"].toDate() : DateTime.now(),
      updatedAt: map["updatedAt"] != null ? map["updatedAt"].toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      // Firebase mein "URL" field name use karo
      "URL": baseUrl,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}

