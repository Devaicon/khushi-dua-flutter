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
                          onPressed: () => Get.back(),
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
                                        child: const ProfileAvatar(size: 90),
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
                        } else {
                          nameController.text = name;
                          return null;
                        }
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
                        if (email == null || email.isEmpty) {
                          return "Email is required".tr;
                        } else {
                          emailController.text = email;
                          return null;
                        }
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
                        } else {
                          passwordController.text = password;
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
          title: Text("Select Your Avatar"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _avatarOption(context, "assets/images/male.png"),
              _avatarOption(context, "assets/images/female.png"),
            ],
          ),
        );
      },
    );

    if (avatarPath != null) {
      Get.find<UserController>().setAvatar(avatarPath);
    }
  }

  Widget _avatarOption(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, imagePath); // Return selected image path
      },
      child: Image.asset(imagePath, width: 80, height: 80),
    );
  }
}
