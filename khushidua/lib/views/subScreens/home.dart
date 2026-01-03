import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/userData.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../models/categoryModel.dart';
import 'categoryDetailScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> colors = [
    Color(0xff9DD6F4),
    Color(0xffFFD5EB),
    Color(0xffDAFFF7),
    Color(0xffF9FFB5),
    Color(0xffFFE1B5),
    Color(0xffF9D7D6),
    Color(0xffD0FFB9),
    Color(0xffDFF2FF),
    Color(0xffD7D9FF),
    Color(0xffDAD1FE),
    Color(0xffC0E9FF),
    Color(0xffE4FEFF),
  ];

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedLang = await prefs.getString("selectedLanguage");

    Get.find<UserController>().setSelectedLanguage(selectedLang ?? "English");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder<ThemeController>(
        builder: (themeController) {
          return GetBuilder<CategoryController>(
            builder: (categoryController) {
              return Scaffold(
                backgroundColor: rwhite,
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      //top bar
                      FadeInAnimationTTB(
                        delay: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            GetBuilder<UserController>(
                              builder: (userController) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    border: Border.all(
                                      color:
                                          themeController.selectedAgeGroup == 0
                                          ? rpink
                                          : themeController.selectedAgeGroup ==
                                                1
                                          ? rblue
                                          : rgreen,
                                      width: 3,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: userController.avatar != ""
                                      ? ClipOval(
                                          child: Image.asset(
                                            userController.avatar,
                                          ),
                                        )
                                      : SizedBox(),
                                );
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Assalam o Alaikum".tr,
                                  style: TextStyle(color: rhint, fontSize: 12),
                                ),
                                Text(
                                  isLoggedIn ? userName : "Guest User",
                                  style: TextStyle(
                                    color: rtext,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ).marginSymmetric(horizontal: 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: themeController.selectedAgeGroup == 0
                                        ? rpink
                                        : themeController.selectedAgeGroup == 1
                                        ? rblue
                                        : rgreen,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: GetBuilder<UserController>(
                                    builder: (userController) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.currency_bitcoin,
                                            color: rblack,
                                          ),
                                          Text(
                                            "$points",
                                            style: TextStyle(
                                              color: rblack,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ).paddingSymmetric(
                                        horizontal: 12,
                                        vertical: 3,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).marginOnly(top: 8),
                      ),
                      SizedBox(height: 20),
                      //banner
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: themeController.selectedAgeGroup == 0
                              ? rpink.withOpacity(0.2)
                              : themeController.selectedAgeGroup == 1
                              ? rblue.withOpacity(0.2)
                              : rgreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ready to learn and play?".tr,
                                    style: TextStyle(
                                      color: rhint,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "If you listen to all available duas you unlock all duas"
                                        .tr,
                                    style: TextStyle(
                                      color: rtext,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      20.0,
                                    ), // Rounded corners
                                    child: LinearProgressIndicator(
                                      value: 0.35,
                                      minHeight: 12.0,
                                      backgroundColor: rpurple.withOpacity(
                                        0.5,
                                      ), // Unfilled color with 50% opacity
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        rpurple,
                                      ),
                                    ),
                                  ).marginOnly(top: 10),
                                ],
                              ).marginOnly(left: 12),
                            ),
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                "assets/images/homeBannerImage.png",
                              ).marginOnly(right: 12),
                            ),
                          ],
                        ).marginAll(12),
                      ),
                      //age groups
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              themeController.setSelectedAgeGroup(0);
                            },
                            child: Container(
                              width: 110,
                              height: 40,
                              decoration: BoxDecoration(
                                color: themeController.selectedAgeGroup == 0
                                    ? rpink
                                    : rwhite,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: themeController.selectedAgeGroup == 0
                                      ? rpink
                                      : themeController.selectedAgeGroup == 1
                                      ? rblue
                                      : rgreen,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Little Kids".tr,
                                style: TextStyle(
                                  color: rtext,
                                  fontWeight:
                                      themeController.selectedAgeGroup == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              themeController.setSelectedAgeGroup(1);
                            },
                            child: Container(
                              width: 110,
                              height: 40,
                              decoration: BoxDecoration(
                                color: themeController.selectedAgeGroup == 1
                                    ? rblue
                                    : rwhite,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: themeController.selectedAgeGroup == 0
                                      ? rpink
                                      : themeController.selectedAgeGroup == 1
                                      ? rblue
                                      : rgreen,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Older Kids".tr,
                                style: TextStyle(
                                  color: rtext,
                                  fontWeight:
                                      themeController.selectedAgeGroup == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              themeController.setSelectedAgeGroup(2);
                            },
                            child: Container(
                              width: 110,
                              height: 40,
                              decoration: BoxDecoration(
                                color: themeController.selectedAgeGroup == 2
                                    ? rgreen
                                    : rwhite,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: themeController.selectedAgeGroup == 0
                                      ? rpink
                                      : themeController.selectedAgeGroup == 1
                                      ? rblue
                                      : rgreen,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Grown ups".tr,
                                style: TextStyle(
                                  color: rtext,
                                  fontWeight:
                                      themeController.selectedAgeGroup == 2
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).marginOnly(top: 12),
                      //grid tiles
                      FadeInAnimationBTT(
                        delay: 1,
                        child: GetBuilder<ThemeController>(
                          builder: (themeController) {
                            List<CategoryModel> filteredCategories =
                                categoryController.allCategories.where((
                                  category,
                                ) {
                                  if (themeController.selectedAgeGroup == 0) {
                                    return category.littleKids;
                                  } else if (themeController.selectedAgeGroup ==
                                      1) {
                                    return category.olderKids;
                                  } else {
                                    return category.grownUps;
                                  }
                                }).toList();

                            filteredCategories.removeWhere(
                              (element) => element.isEnabled == false,
                            );

                            return GridView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(10.0),
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).size.width <= 450
                                        ? 3
                                        : 6,
                                    crossAxisSpacing: 10.0,
                                    mainAxisSpacing: 10.0,
                                  ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                return CategoryTile(
                                  colors[index % colors.length],
                                  category,
                                );
                              },
                            ).marginOnly(top: 12);
                          },
                        ),
                      ),
                    ],
                  ).marginSymmetric(horizontal: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryTile extends StatefulWidget {
  final Color color;
  final CategoryModel categoryModel;

  const CategoryTile(this.color, this.categoryModel, {super.key});

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(
          CategoryDetailScreen(widget.categoryModel, widget.color),
          transition: Transition.upToDown,
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(widget.categoryModel.logo, width: 40, height: 40),
            SizedBox(height: 4),
            Text(
              widget.categoryModel.getName(
                Get.find<UserController>().selectedLanguage,
              ),
              textAlign: TextAlign.center,
            ).marginSymmetric(horizontal: 5),
          ],
        ),
      ),
    );
  }
}
