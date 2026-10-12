import 'package:get/get.dart';

import '../models/userModel.dart';
import '../services/userService.dart';

class UserController extends GetxController {
  final List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

  bool _loaded = false;
  bool get loaded => _loaded;

  void getAllUsers() => UserService().getAllUsers();

  void addUserToList(UserModel userModel, {bool shouldUpdate = true}) {
    final existingIndex = _allUsers.indexWhere((u) => u.id == userModel.id);
    if (existingIndex == -1) {
      _allUsers.add(userModel);
    } else {
      _allUsers[existingIndex] = userModel;
    }
    if (shouldUpdate) markLoaded();
  }

  void removeUser(String id) => _allUsers.removeWhere((u) => u.id == id);

  /// Most recently active first.
  void markLoaded() {
    _loaded = true;
    _allUsers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    update();
  }
}
