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

  factory ManagementModel.fromMap(Map<String, dynamic> map) {
    return ManagementModel(
        id: map["id"],
        email: map["email"],
        firstName: map["firstName"],
        lastName: map["lastName"],
        role: map["role"],
        createdAt: map["createdAt"].toDate(),
        updatedAt: map["updatedAt"].toDate());
  }
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
