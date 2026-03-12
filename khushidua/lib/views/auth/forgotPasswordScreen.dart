import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../services/authService.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
              // Premium Header
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
                        top: 20,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FadeInAnimationTTB(
                              delay: 1,
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 80,
                                color: rbluedark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeInAnimationBTT(
                              delay: 1.2,
                              child: Text(
                                "Reset Password".tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: rblack,
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInAnimationBTT(
                        delay: 1.4,
                        child: Text(
                          "Forgot your password?".tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rblack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInAnimationBTT(
                        delay: 1.6,
                        child: Text(
                          "Enter your email address below and we'll send you a link to reset your password.".tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Email Field
                      FadeInAnimationBTT(
                        delay: 1.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email".tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: rblack,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email is required".tr;
                                }
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return "Please enter a valid email address".tr;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your email'.tr,
                                prefixIcon: const Icon(Icons.email_outlined, color: rbluedark),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: rbluedark, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Reset Button
                      FadeInAnimationBTT(
                        delay: 2.0,
                        child: InkWell(
                          onTap: _isLoading ? null : _handlePasswordReset,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: _isLoading ? Colors.grey : rbluedark,
                              boxShadow: [
                                if (!_isLoading)
                                  BoxShadow(
                                    color: rbluedark.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: rwhite)
                                : Text(
                                    "Send Reset Link".tr,
                                    style: const TextStyle(
                                      color: rwhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthService().sendPasswordResetEmail(_emailController.text.trim());
        // Success snackbar is handled within AuthService
        // Optionally navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Get.back();
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
