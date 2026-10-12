class MLSettingsModel {
  String id = "";
  String baseUrl = "";

  /// Whether the app's Practice button is live; off greys it out. A
  /// document without the field counts as on, as before the switch.
  bool practiceEnabled = true;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  MLSettingsModel({
    required this.id,
    required this.baseUrl,
    required this.createdAt,
    required this.updatedAt,
    this.practiceEnabled = true,
  });

  factory MLSettingsModel.fromMap(Map<String, dynamic> map) {
    return MLSettingsModel(
      id: map["id"] ?? "MemoizationURL",
      // Firebase mein field name "URL" hai, not "baseUrl"
      baseUrl: map["URL"] ?? map["baseUrl"] ?? "",
      createdAt: map["createdAt"] != null ? map["createdAt"].toDate() : DateTime.now(),
      updatedAt: map["updatedAt"] != null ? map["updatedAt"].toDate() : DateTime.now(),
      practiceEnabled: map["practiceEnabled"] is bool ? map["practiceEnabled"] : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      // Firebase mein "URL" field name use karo
      "URL": baseUrl,
      "practiceEnabled": practiceEnabled,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}

