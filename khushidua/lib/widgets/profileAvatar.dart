import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/userController.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final bool showBorder;

  const ProfileAvatar({super.key, this.size = 90, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
      builder: (userController) {
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            Color borderColor = themeController.selectedAgeGroup == 0
                ? rpink
                : themeController.selectedAgeGroup == 1
                ? rblue
                : rgreen;

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: showBorder
                    ? Border.all(color: borderColor, width: 3)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    borderColor.withOpacity(0.8),
                    borderColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: userController.avatar != ""
                  ? ClipOval(
                      child: Image.asset(
                        userController.avatar,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitial(userController.userName),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty || name == "Guest User") return "G";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
