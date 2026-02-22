import 'package:get/get.dart';

import '../models/userModel.dart';
import '../services/userService.dart';

class UserController extends GetxController {
  final List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

  getAllUsers() {
    UserService().getAllUsers();
  }

  void addUserToList(UserModel userModel, {bool shouldUpdate = true}) {
    int existingIndex = _allUsers.indexWhere((cat) => cat.id == userModel.id);
    if (existingIndex == -1) {
      _allUsers.add(userModel);
    } else {
      _allUsers[existingIndex] = userModel;
    }
    _allUsers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (shouldUpdate) update();
  }
}
