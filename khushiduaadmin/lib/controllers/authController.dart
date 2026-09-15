import 'package:get/get.dart';
import 'package:khushiduaadmin/models/managementModel.dart';
import 'package:khushiduaadmin/services/authService.dart';

class AuthController extends GetxController {
  ManagementModel _adminModel = ManagementModel.empty();
  ManagementModel get adminModel => _adminModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Set when someone signs in with a Google account that isn't an admin.
  AdminSignInResult? _lastDenied;
  AdminSignInResult? get lastDenied => _lastDenied;

  setLoading(bool value) {
    _isLoading = value;
    update();
  }

  setManagementUserModel(ManagementModel managementModel) {
    _adminModel = managementModel;
    update();
  }

  Future<void> signInWithGoogle() async {
    _error = null;
    _lastDenied = null;
    setLoading(true);

    final result = await AuthService().signInWithGoogle();
    switch (result.status) {
      case AdminSignInStatus.signedIn:
        _adminModel = result.admin!;
        setLoading(false);
        Get.offAllNamed('/dashboard');
        return;
      case AdminSignInStatus.notAnAdmin:
        _lastDenied = result;
        break;
      case AdminSignInStatus.failed:
        _error = result.message;
        break;
      case AdminSignInStatus.cancelled:
        break;
    }
    setLoading(false);
  }

  /// Called when the dashboard opens. Sends the browser to the login screen
  /// when there is no signed-in admin.
  Future<void> restoreSession() async {
    final admin = await AuthService().restoreSession();
    if (admin == null) {
      Get.offAllNamed('/login');
      return;
    }
    setManagementUserModel(admin);
  }

  Future<void> signOut() async {
    await AuthService().signOut();
    _adminModel = ManagementModel.empty();
    update();
    Get.offAllNamed('/login');
  }

  Future<String?> inviteAdmin({
    required String email,
    required String role,
    required String firstName,
    required String lastName,
  }) =>
      AuthService().inviteAdmin(
          email: email, role: role, firstName: firstName, lastName: lastName);

  Future<String?> cancelInvite(String email) =>
      AuthService().cancelInvite(email);

  Future<String?> revokeAdmin(String uid) => AuthService().revokeAdmin(uid);
}
