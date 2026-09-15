import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../controllers/authController.dart';
import '../../services/authService.dart';
import '../../widgets/customLoading.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBg,
      body: GetBuilder<AuthController>(
        builder: (auth) {
          return Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/logo.png",
                        width: 180,
                        height: 180,
                        fit: BoxFit.fill,
                      ),
                      const Text(
                        "Log In",
                        style: TextStyle(
                            color: rWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: "fontBold"),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Sign in with your Google account",
                        style: TextStyle(color: rHint, fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              auth.isLoading ? null : auth.signInWithGoogle,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text(
                            "Sign in with Google",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rGreen,
                            foregroundColor: rWhite,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: rRed),
                        ),
                      ],
                      if (auth.lastDenied != null) ...[
                        const SizedBox(height: 24),
                        _NotAnAdminPanel(result: auth.lastDenied!),
                      ],
                    ],
                  ),
                ),
              ),
              if (auth.isLoading) const CustomLoading(),
            ],
          );
        },
      ),
    );
  }
}

class _NotAnAdminPanel extends StatelessWidget {
  const _NotAnAdminPanel({required this.result});

  final AdminSignInResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: rYellow),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Google account isn't an admin",
            style: TextStyle(color: rWhite, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask a super admin to invite ${result.email ?? 'this account'}, then sign in again.",
            style: const TextStyle(color: rHint),
          ),
          const SizedBox(height: 12),
          // Selectable so the very first super admin can copy their UID into
          // the Firebase Console.
          SelectableText(
            "Account ID: ${result.uid ?? '-'}",
            style: const TextStyle(
                color: rHint, fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
