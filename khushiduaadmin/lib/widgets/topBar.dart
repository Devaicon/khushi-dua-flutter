import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../controllers/authController.dart';

class TopBar extends StatefulWidget {
  final title;
  const TopBar({super.key, required this.title});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return Container(
          decoration: BoxDecoration(
              color: rBg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                  child: Text(
                "${widget.title}",
                style: const TextStyle(
                    color: rWhite, fontSize: 20, fontWeight: FontWeight.bold),
              )),
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    authController.adminModel.firstName.isEmpty
                        ? "Admin"
                        : "${authController.adminModel.firstName} ${authController.adminModel.lastName}",
                    style: const TextStyle(color: rWhite),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: rBlack),
                    alignment: Alignment.center,
                    child: Text(
                      authController.adminModel.firstName.isEmpty
                          ? "A"
                          : authController.adminModel.firstName[0]
                              .toUpperCase(),
                      style: const TextStyle(
                          color: rWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ).marginOnly(left: 12)
                ],
              ))
            ],
          ).marginSymmetric(horizontal: 20, vertical: 5),
        );
      },
    );
  }
}
