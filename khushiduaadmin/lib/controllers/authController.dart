import 'package:get/get.dart';
import 'package:khushiduaadmin/models/managementModel.dart';
import 'package:khushiduaadmin/services/authService.dart';

class AuthController extends GetxController {
  ManagementModel _adminModel = ManagementModel(
      id: '',
      email: '',
      firstName: '',
      lastName: '',
      role: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now());
  ManagementModel get adminModel => _adminModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  createAdmin() {
    AuthService().createAdmin();
  }

  setLoading(bool value) {
    _isLoading = value;
    update();
  }

  setManagementUserModel(ManagementModel managementModel) {
    _adminModel = managementModel;
    update();
  }

  getAdminDetails() async {
    await AuthService().getAdminDetails();
  }

  login(String email, String password) {
    AuthService().login(email, password);
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    _isLoading = true;
    update();
    String? result =
        await AuthService().changePassword(currentPassword, newPassword);
    _isLoading = false;
    update();
    return result;
  }

  Future<String?> createNewAdmin(String email, String password,
      String firstName, String lastName, String role) async {
    _isLoading = true;
    update();
    String? result = await AuthService()
        .createNewAdmin(email, password, firstName, lastName, role);
    _isLoading = false;
    update();
    return result;
  }
}
