import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../controllers/authController.dart';
import '../../widgets/topBar.dart';
import '../../widgets/customLoading.dart';
import '../../widgets/adminAccessCard.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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
                  const TopBar(title: "Profile"),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
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
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Profile Information",
                                    style: TextStyle(
                                      color: rWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: rGreen,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          authController.adminModel.firstName
                                                  .isNotEmpty
                                              ? authController
                                                  .adminModel.firstName[0]
                                              : 'A',
                                          style: const TextStyle(
                                            color: rWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${authController.adminModel.firstName} ${authController.adminModel.lastName}",
                                              style: const TextStyle(
                                                color: rWhite,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              authController.adminModel.email,
                                              style: const TextStyle(
                                                color: rHint,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: rGreen.withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border:
                                                    Border.all(color: rGreen),
                                              ),
                                              child: Text(
                                                authController.adminModel.role,
                                                style: const TextStyle(
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
                          const SizedBox(width: 20),
                          // Who can use the admin panel
                          const Expanded(
                            flex: 1,
                            child: AdminAccessCard(),
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
                  child: const CustomLoading(),
                ),
            ],
          );
        },
      ),
    );
  }
}
