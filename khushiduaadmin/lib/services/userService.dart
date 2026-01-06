import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/models/userModel.dart';

class UserService {
  final UserController _userController = Get.find<UserController>();

  getAllUsers() async {
    userRef.snapshots().listen((event) {
      bool changed = false;
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _userController.addUserToList(
            UserModel.fromMap(element.doc.data()!),
            shouldUpdate: false,
          );
          changed = true;
        }
      }
      if (changed) _userController.update();
    });
  }
}
