class UserModel {
  String id = "";
  String name = "";
  String email = "";
  bool isLoggedIn = false;
  int points = 0;
  List<String> readDuas = [];
  bool isMember = false;
  bool isBlocked = false;
  String avatar = "";
  String fcmToken = "";
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.isLoggedIn,
    required this.isMember,
    required this.isBlocked,
    required this.readDuas,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map["id"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      points: map["points"] ?? 0,
      isLoggedIn: map["isLoggedIn"] ?? false,
      isMember: map["isMember"] ?? false,
      isBlocked: map["isBlocked"] ?? false,
      readDuas: List<String>.from(map["readDuas"] ?? []),
      avatar: map["avatar"] ?? "",
      createdAt: map["createdAt"]?.toDate() ?? DateTime.now(),
      updatedAt: map["updatedAt"]?.toDate() ?? DateTime.now(),
      fcmToken: map["fcmToken"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "points": points,
      "isLoggedIn": isLoggedIn,
      "isMember": isMember,
      "isBlocked": isBlocked,
      "readDuas": readDuas,
      "avatar": avatar,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "fcmToken": fcmToken,
    };
  }
}
