import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String id = "";
  String title = "";
  String message = "";
  DateTime createdAt = DateTime.now();

  /// The user the notification was sent to, or null for everyone.
  String? sentTo;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.sentTo,
  });

  /// Tolerates a document written a moment ago: the Cloud Function stamps
  /// `createdAt` with a server timestamp, which reads as null until the server
  /// has resolved it. That used to throw and drop the notification.
  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final created = map["createdAt"];
    return NotificationModel(
      id: (map["id"] as String?) ?? docId ?? "",
      title: (map["title"] as String?) ?? "",
      message: (map["message"] as String?) ?? "",
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      sentTo: map["sentTo"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "message": message,
      "createdAt": createdAt,
      "sentTo": sentTo,
    };
  }
}
