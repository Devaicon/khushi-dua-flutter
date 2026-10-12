import 'modelValues.dart';

class UserModel {
  String id = "";
  String name = "";
  String email = "";
  bool isLoggedIn = false;
  int points = 0;
  String fcmToken="";
  List<String> readDuas = [];
  bool isMember = false;
  bool isBlocked=false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UserModel(
      {required this.id,
      required this.name,
      required this.email,
      required this.points,
        required this.fcmToken,
      required this.isLoggedIn,
      required this.isMember,
        required this.isBlocked,
      required this.readDuas,
      required this.createdAt,
      required this.updatedAt});

  /// Lenient: profiles written by older app versions miss fields, and one
  /// bad profile used to crash the whole Users list.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        id: readString(map["id"]),
        name: readString(map["name"]),
        email: readString(map["email"]),
        points: readInt(map["points"]),
        fcmToken: readString(map["fcmToken"]),
        isLoggedIn: readBool(map["isLoggedIn"], fallback: false),
        isMember: readBool(map["isMember"], fallback: false),
        isBlocked: readBool(map["isBlocked"], fallback: false),
        readDuas: readStringList(map["readDuas"]),
        createdAt: readDate(map["createdAt"]),
        updatedAt: readDate(map["updatedAt"]));
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "points": points,
      "isLoggedIn": isLoggedIn,
      "isMember": isMember,
      "isBlocked":isBlocked,
      "readDuas": readDuas,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "fcmToken":fcmToken
    };
  }
}
