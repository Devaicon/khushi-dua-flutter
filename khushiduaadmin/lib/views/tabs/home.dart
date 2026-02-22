import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/authController.dart';
import 'package:khushiduaadmin/controllers/categoryController.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/widgets/topBar.dart';
import '../../constants/colors.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: "Dashboard"),
            const SizedBox(height: 30),

            FadeInDown(
              child: GetBuilder<AuthController>(
                builder: (auth) => Text(
                  "Welcome back, ${auth.adminModel.firstName}! 👋",
                  style: const TextStyle(
                    color: rWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Text(
              "Here's what's happening with your app today.",
              style: TextStyle(color: rHint, fontSize: 16),
            ).marginOnly(top: 8),

            const SizedBox(height: 40),

            // Stats Grid
            Row(
              children: [
                GetBuilder<CategoryController>(
                  builder: (cat) => _buildStatCard(
                    title: "Total Categories",
                    icon: "assets/svgs/coins.svg",
                    color: const Color(0xff955C00),
                    count: cat.allCategories.length,
                    delay: 200,
                  ),
                ),
                const SizedBox(width: 20),
                GetBuilder<CategoryController>(
                  builder: (cat) => _buildStatCard(
                    title: "Sub Categories",
                    icon: "assets/svgs/coins.svg",
                    color: const Color(0xff2E5A95),
                    count: cat.allSubCategories.length,
                    delay: 400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GetBuilder<DuaController>(
                  builder: (dua) => _buildStatCard(
                    title: "Total Duas",
                    icon: "assets/svgs/ad.svg",
                    color: rGreen,
                    count: dua.allDuas.length,
                    delay: 600,
                  ),
                ),
                const SizedBox(width: 20),
                GetBuilder<UserController>(
                  builder: (user) => _buildStatCard(
                    title: "Total Users",
                    icon: "assets/svgs/users.svg",
                    color: const Color(0xff9B51E0),
                    count: user.allUsers.length,
                    delay: 800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Quick Actions or Recent Section
            FadeInUp(
              delay: const Duration(milliseconds: 1000),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: rBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: rWhite.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "App Health Status",
                      style: TextStyle(
                        color: rWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow("Firebase Cloud Firestore", "Operational",
                        Colors.green),
                    _buildStatusRow(
                        "Firebase Authentication", "Operational", Colors.green),
                    _buildStatusRow("Storage System", "Active", Colors.green),
                    _buildStatusRow(
                        "ML Prediction Engine", "Connected", rGreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String icon,
    required Color color,
    required int count,
    required int delay,
  }) {
    return Expanded(
      child: FadeInLeft(
        delay: Duration(milliseconds: delay),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: rBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  icon,
                  color: color,
                  width: 28,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: count),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Text(
                        _formatNumber(value),
                        style: const TextStyle(
                          color: rWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: rHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String service, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: const TextStyle(color: rWhite, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
