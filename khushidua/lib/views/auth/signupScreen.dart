import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/userData.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../services/authService.dart';
import '../../widgets/profileAvatar.dart';
import 'loginScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  var formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rwhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                elevation: 8,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Get.back();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: rblack,
                          ),
                        ),
                      ),
                      Center(
                        child: GetBuilder<ThemeController>(
                          builder: (themeController) {
                            return GetBuilder<UserController>(
                              builder: (userController) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FadeInAnimationTTB(
                                      delay: 1,
                                      child: InkWell(
                                        onTap: _showAvatarPopup,
                                        borderRadius: BorderRadius.circular(50),
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            const ProfileAvatar(size: 90),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 14,
                                                color: rbluedark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    FadeInAnimationBTT(
                                      delay: 1,
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ).marginOnly(top: 8),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: rblack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextFormField(
                      controller: nameController,
                      validator: (name) {
                        if (name == null || name.isEmpty) {
                          return "Name is required".tr;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Name'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ).marginOnly(top: 10),
                    Text(
                      "Email".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: rblack,
                        fontWeight: FontWeight.bold,
                      ),
                    ).marginOnly(top: 20),
                    TextFormField(
                      controller: emailController,
                      validator: (email) {
                        if (email == null || email.trim().isEmpty) {
                          return "Email is required".tr;
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(email.trim())) {
                          return "Please enter a valid email address".tr;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Email'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ).marginOnly(top: 12),
                    Text(
                      "Password".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: rblack,
                        fontWeight: FontWeight.bold,
                      ),
                    ).marginOnly(top: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      validator: (password) {
                        if (password == null || password.isEmpty) {
                          return "Password is required".tr;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Password'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ).marginOnly(top: 12),
                    Text(
                      "Confirm Password".tr,
                      style: const TextStyle(
                        fontSize: 18,
                        color: rblack,
                        fontWeight: FontWeight.bold,
                      ),
                    ).marginOnly(top: 20),
                    TextFormField(
                      controller: cPasswordController,
                      obscureText: true,
                      validator: (cPassword) {
                        if (cPassword == null || cPassword.isEmpty) {
                          return "Confirm your password".tr;
                        } else if (passwordController.text != cPassword) {
                          return "Passwords don't match";
                        } else {
                          cPasswordController.text = cPassword;
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter Password'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ).marginOnly(top: 12),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _isLoading
                          ? null
                          : () async {
                              if (formKey.currentState != null &&
                                  formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  await AuthService().register(
                                    emailController.text,
                                    passwordController.text,
                                    nameController.text,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              }
                            },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _isLoading ? Colors.grey : rbluedark,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Create an account".tr,
                                style: const TextStyle(
                                  color: rwhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Already have an account? ".tr,
                            style: const TextStyle(color: rblack),
                          ),
                          InkWell(
                            onTap: () {
                              Get.to(
                                const LoginScreen(),
                                transition: Transition.downToUp,
                              );
                            },
                            child: Text(
                              "Login now! ".tr,
                              style: const TextStyle(
                                color: rbluedark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).marginSymmetric(horizontal: 20, vertical: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarPopup() async {
    String? avatarPath = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              "Select Your Avatar".tr,
              style: const TextStyle(
                color: rbluedark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _avatarOption(context, "assets/images/male.png"),
                _avatarOption(context, "assets/images/female.png"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel".tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );

    if (avatarPath != null) {
      Get.find<UserController>().setAvatar(avatarPath);
    }
  }

  Widget _avatarOption(BuildContext context, String imagePath) {
    return InkWell(
      onTap: () => Navigator.pop(context, imagePath),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 80, height: 80),
            const SizedBox(height: 8),
            Text(
              imagePath.contains("male") ? "Boy".tr : "Girl".tr,
              style: const TextStyle(
                color: rbluedark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
