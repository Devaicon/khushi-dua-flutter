import 'package:cloud_firestore/cloud_firestore.dart';

class ManagementModel {
  String id = "";
  String firstName = "";
  String lastName = "";
  String role = "";
  String email = "";
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  ManagementModel(
      {required this.id,
      required this.email,
      required this.firstName,
      required this.lastName,
      required this.role,
      required this.createdAt,
      required this.updatedAt});

  factory ManagementModel.empty() => ManagementModel(
      id: '',
      email: '',
      firstName: '',
      lastName: '',
      role: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now());

  factory ManagementModel.fromMap(Map<String, dynamic> map) {
    return ManagementModel(
        id: (map["id"] ?? "").toString(),
        email: (map["email"] ?? "").toString(),
        firstName: (map["firstName"] ?? "").toString(),
        lastName: (map["lastName"] ?? "").toString(),
        // Never default to Super_Admin: a malformed record must not escalate.
        role: (map["role"] ?? "Admin").toString(),
        createdAt: _toDate(map["createdAt"]),
        updatedAt: _toDate(map["updatedAt"]));
  }

  /// The first super admin is created by hand in the Firebase Console, where a
  /// timestamp is easy to leave out or enter as a string.
  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  bool get isSuperAdmin => role == "Super_Admin";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "role": role,
      "createdAt": createdAt,
      "updatedAt": updatedAt
    };
  }
}
