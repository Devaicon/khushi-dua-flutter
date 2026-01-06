import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../controllers/authController.dart';
import '../../widgets/customLoading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isObsecure = true;
  TextEditingController emailController =
      TextEditingController(text: "admin@gmail.com");
  TextEditingController passwordController =
      TextEditingController(text: "123456");

  // @override
  // void initState() {
  //  Get.find<AuthController>().createAdmin();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBg,
      body: GetBuilder<AuthController>(
        builder: (authController) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/logo.png",
                          width: 180,
                          height: 180,
                          fit: BoxFit.fill,
                        )
                      ],
                    ),
                    const Text(
                      "Log In",
                      style: TextStyle(
                          color: rWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: "fontBold"),
                    ),
                    const Text(
                      "Please Log In to your account",
                      style: TextStyle(
                          color: rHint,
                          fontSize: 18,
                          fontWeight: FontWeight.normal),
                    ),
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            child: TextFormField(
                              cursorColor: rGreen,
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (email) {
                                if (email == null || email.isEmpty) {
                                  return "Email required";
                                } else if (!RegExp(
                                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                    .hasMatch(email)) {
                                  return "Enter a valid email address";
                                } else {
                                  return null;
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.transparent,
                                hintText: 'Email address',
                                hintStyle: const TextStyle(
                                  color: rHint,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: rHint,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: rHint,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            child: TextFormField(
                              cursorColor: rGreen,
                              controller: passwordController,
                              validator: (password) {
                                if (password == null || password.isEmpty) {
                                  return "Password is required";
                                } else {
                                  return null;
                                }
                              },
                              obscureText: isObsecure,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.transparent,
                                hintText: 'Password',
                                suffixIcon: InkWell(
                                    splashColor: Colors.transparent,
                                    onTap: () {
                                      setState(() {
                                        isObsecure = !isObsecure;
                                      });
                                    },
                                    child: Icon(isObsecure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined)),
                                hintStyle: const TextStyle(
                                  color: rHint,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: rHint,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: rHint,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ).marginOnly(top: 12),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  // Get.to(ForgotPassword(),transition: Transition.downToUp);
                                },
                                child: const Text(
                                  "Forgot password",
                                  style: TextStyle(color: rHint),
                                ),
                              ),
                            ),
                          ).marginOnly(top: 20),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              if (formKey.currentState!.validate()) {
                                authController.login(emailController.text,
                                    passwordController.text);
                                // authController.setLoading(true);
                              } else {
                                return;
                              }
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.35,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: rGreen,
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: const Text(
                                "Log In",
                                style: TextStyle(color: rWhite, fontSize: 16),
                              ),
                            ).marginOnly(top: 20),
                          ),
                        ],
                      ).marginOnly(top: 20),
                    ),
                  ],
                ),
              ),
              Visibility(
                  visible: authController.isLoading,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: rWhite.withOpacity(0.2),
                      child: const CustomLoading()))
            ],
          );
        },
      ),
    );
  }
}
