import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/authController.dart';
import '../../services/authService.dart';
import '../../widgets/ui.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // The app's sign-in gradient.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
          ),
        ),
        child: GetBuilder<AuthController>(
          builder: (auth) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Space.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AdminCard(
                    padding: const EdgeInsets.all(Space.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset("assets/images/logo.png",
                              width: 96, height: 96),
                        ),
                        const SizedBox(height: Space.xl),
                        const Text(
                          "Khushi Dua Admin",
                          style: TextStyle(
                              color: Palette.brand,
                              fontSize: 26,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: Space.sm),
                        const Text(
                          "Sign in with the Google account you were invited with.",
                          textAlign: TextAlign.center,
                          style: AdminText.muted,
                        ),
                        const SizedBox(height: Space.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AdminButton(
                            label: "Sign in with Google",
                            icon: Icons.login_rounded,
                            busy: auth.isLoading,
                            onPressed: auth.signInWithGoogle,
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: Space.lg),
                          Text(
                            auth.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Palette.danger),
                          ),
                        ],
                        if (auth.lastDenied != null) ...[
                          const SizedBox(height: Space.xl),
                          _NotAnAdminPanel(result: auth.lastDenied!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
        color: Palette.warning.withValues(alpha: 0.08),
        borderRadius: Radii.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Google account isn't an admin",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask a super admin to invite ${result.email ?? 'this account'}, then sign in again.",
            style: AdminText.muted,
          ),
          const SizedBox(height: 12),
          // Selectable so the very first super admin can copy their UID into
          // the Firebase Console.
          SelectableText(
            "Account ID: ${result.uid ?? '-'}",
            style: AdminText.mono,
          ),
        ],
      ),
    );
  }
}
