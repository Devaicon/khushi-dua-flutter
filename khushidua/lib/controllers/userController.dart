import 'package:get/get.dart';
import 'package:khushidua/services/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/userData.dart' as ud;
import '../models/userModel.dart';
import 'localization.dart';

class UserController extends GetxController {
  String _userName = "";
  String get userName => _userName;
  int _points = 0;
  int get points => _points;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String _avatar = "";
  String get avatar => _avatar;

  String _selectedLanguage = "English";
  String get selectedLanguage => _selectedLanguage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  setSelectedLanguage(String selectedLan) {
    _selectedLanguage = selectedLan;
    Localization.changeLocale(selectedLan);
    update();
  }

  setUserName(String value) {
    _userName = value;
    ud.userName = value;
    update();
  }

  setPoints(int value) async {
    _points = value;
    ud.points = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("userPoints", value);
    update();
  }

  setLoggedIn(bool value) {
    _isLoggedIn = value;
    ud.isLoggedIn = value;
    if (value == false) {
      ud.userName = "Guest User";
    }
    update();
  }

  setAvatar(String value) async {
    _avatar = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("userAvatar", value);
    update();
  }

  getUserData(String userId) async {
    await AuthService().getUserData(userId);
  }

  setUserModel(UserModel user) {
    _userModel = user;
    setUserName(user.name);
    setPoints(user.points);
    setLoggedIn(user.isLoggedIn);
    update();
  }
}
