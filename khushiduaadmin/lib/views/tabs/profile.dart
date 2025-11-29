import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../controllers/authController.dart';
import '../../widgets/topBar.dart';
import '../../widgets/customLoading.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Change Password Controllers
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordObscure = true;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  // Add Admin Controllers
  final GlobalKey<FormState> _addAdminFormKey = GlobalKey<FormState>();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final TextEditingController _adminFirstNameController = TextEditingController();
  final TextEditingController _adminLastNameController = TextEditingController();
  final TextEditingController _adminRoleController = TextEditingController();
  bool _isAdminPasswordObscure = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminRoleController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_changePasswordFormKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        Get.snackbar(
          "Error",
          "New password and confirm password do not match",
          backgroundColor: rRed,
          colorText: rWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      AuthController authController = Get.find<AuthController>();
      String? result = await authController.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (result == null) {
        Get.snackbar(
          "Success",
          "Password changed successfully",
          backgroundColor: rGreen,
          colorText: rWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        Get.snackbar(
          "Error",
          result,
          backgroundColor: rRed,
          colorText: rWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _createNewAdmin() async {
    if (_addAdminFormKey.currentState!.validate()) {
      AuthController authController = Get.find<AuthController>();
      String? result = await authController.createNewAdmin(
        _adminEmailController.text,
        _adminPasswordController.text,
        _adminFirstNameController.text,
        _adminLastNameController.text,
        _adminRoleController.text.isEmpty ? "Admin" : _adminRoleController.text,
      );

      if (result == null) {
        Get.snackbar(
          "Success",
          "New admin created successfully",
          backgroundColor: rGreen,
          colorText: rWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
        _adminEmailController.clear();
        _adminPasswordController.clear();
        _adminFirstNameController.clear();
        _adminLastNameController.clear();
        _adminRoleController.clear();
      } else {
        Get.snackbar(
          "Error",
          result,
          backgroundColor: rRed,
          colorText: rWhite,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<AuthController>(
        builder: (authController) {
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(title: "Profile"),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Information Card
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: rBg,
                              ),
                              padding: EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Profile Information",
                                    style: TextStyle(
                                      color: rWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: rGreen,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "${authController.adminModel.firstName.isNotEmpty ? authController.adminModel.firstName[0] : 'A'}",
                                          style: TextStyle(
                                            color: rWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${authController.adminModel.firstName} ${authController.adminModel.lastName}",
                                              style: TextStyle(
                                                color: rWhite,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              authController.adminModel.email,
                                              style: TextStyle(
                                                color: rHint,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: rGreen.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: rGreen),
                                              ),
                                              child: Text(
                                                authController.adminModel.role,
                                                style: TextStyle(
                                                  color: rGreen,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          // Change Password and Add Admin Cards
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Change Password Card
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: rBg,
                                  ),
                                  padding: EdgeInsets.all(24),
                                  child: Form(
                                    key: _changePasswordFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Change Password",
                                          style: TextStyle(
                                            color: rWhite,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        _buildPasswordField(
                                          controller: _currentPasswordController,
                                          label: "Current Password",
                                          obscureText: _isCurrentPasswordObscure,
                                          onToggle: () {
                                            setState(() {
                                              _isCurrentPasswordObscure = !_isCurrentPasswordObscure;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Current password is required";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        _buildPasswordField(
                                          controller: _newPasswordController,
                                          label: "New Password",
                                          obscureText: _isNewPasswordObscure,
                                          onToggle: () {
                                            setState(() {
                                              _isNewPasswordObscure = !_isNewPasswordObscure;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "New password is required";
                                            } else if (value.length < 6) {
                                              return "Password must be at least 6 characters";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        _buildPasswordField(
                                          controller: _confirmPasswordController,
                                          label: "Confirm New Password",
                                          obscureText: _isConfirmPasswordObscure,
                                          onToggle: () {
                                            setState(() {
                                              _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Please confirm your password";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 24),
                                        InkWell(
                                          onTap: _changePassword,
                                          child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: rGreen,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Change Password",
                                              style: TextStyle(
                                                color: rWhite,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Add New Admin Card
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: rBg,
                                  ),
                                  padding: EdgeInsets.all(24),
                                  child: Form(
                                    key: _addAdminFormKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Add New Admin",
                                          style: TextStyle(
                                            color: rWhite,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                controller: _adminFirstNameController,
                                                label: "First Name",
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return "First name is required";
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: _buildTextField(
                                                controller: _adminLastNameController,
                                                label: "Last Name",
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return "Last name is required";
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _adminEmailController,
                                          label: "Email",
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Email is required";
                                            } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                                              return "Enter a valid email address";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        _buildPasswordField(
                                          controller: _adminPasswordController,
                                          label: "Password",
                                          obscureText: _isAdminPasswordObscure,
                                          onToggle: () {
                                            setState(() {
                                              _isAdminPasswordObscure = !_isAdminPasswordObscure;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Password is required";
                                            } else if (value.length < 6) {
                                              return "Password must be at least 6 characters";
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _adminRoleController,
                                          label: "Role (optional, defaults to 'Admin')",
                                          validator: null,
                                        ),
                                        SizedBox(height: 24),
                                        InkWell(
                                          onTap: _createNewAdmin,
                                          child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: rGreen,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Create Admin",
                                              style: TextStyle(
                                                color: rWhite,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (authController.isLoading)
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: rBlack.withOpacity(0.7),
                  child: CustomLoading(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: rGreen,
      style: TextStyle(color: rWhite),
      decoration: InputDecoration(
        filled: true,
        fillColor: rBlack,
        labelText: label,
        labelStyle: TextStyle(color: rHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rRed),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      cursorColor: rGreen,
      style: TextStyle(color: rWhite),
      decoration: InputDecoration(
        filled: true,
        fillColor: rBlack,
        labelText: label,
        labelStyle: TextStyle(color: rHint),
        suffixIcon: InkWell(
          onTap: onToggle,
          child: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: rHint,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: rRed),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
