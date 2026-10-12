import 'modelValues.dart';

class NotificationModel{

  String id="";
  String title="";
  String message="";
  DateTime createdAt=DateTime.now();
  String? sentTo;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.sentTo
});

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: readString(map["id"]),
      title: readString(map["title"]),
      message: readString(map["message"]),
      createdAt: readDate(map["createdAt"]),
      sentTo: map["sentTo"] is String ? map["sentTo"] as String : null,
    );
  }

  Map<String, dynamic> toMap(){
    return {
      "id":id,
      "title":title,
      "message":message,
      "createdAt":createdAt,
    };
  }
}