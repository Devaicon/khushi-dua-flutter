import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: GetBuilder<ThemeController>(
        builder: (themeController) {
          return GetBuilder<CategoryController>(
            builder: (categoryController) {
              List<CategoryModel> filteredCategories = categoryController
                  .allCategories
                  .where((category) {
                    if (themeController.selectedAgeGroup == 0) {
                      return category.littleKids;
                    } else if (themeController.selectedAgeGroup == 1) {
                      return category.olderKids;
                    } else {
                      return category.grownUps;
                    }
                  })
                  .toList();

              filteredCategories.removeWhere(
                (element) => element.isEnabled == false,
              );

              if (themeController.selectedAgeGroup == 0) {
                filteredCategories.removeWhere((category) {
                  final categoryName = category.english.toLowerCase();
                  return categoryName.contains('family') &&
                      categoryName.contains('wedding');
                });
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Premium Header
                  SliverToBoxAdapter(
                    child: FadeInAnimationTTB(
                      delay: 1,
                      child: _buildHeader(themeController),
                    ).paddingSymmetric(horizontal: 20, vertical: 10),
                  ),

                  // Premium Banner
                  SliverToBoxAdapter(
                    child: _buildBanner(
                      themeController,
                    ).paddingSymmetric(horizontal: 20),
                  ),

                  // Age Group Selector
                  SliverToBoxAdapter(
                    child: _buildAgeGroupSelector(
                      themeController,
                    ).paddingSymmetric(vertical: 20),
                  ),

                  // Category Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // More compact grid
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final category = filteredCategories[index];
                        return CategoryTile(
                          colors[index % colors.length],
                          category,
                        );
                      }, childCount: filteredCategories.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeController themeController) {
    Color accentColor = themeController.selectedAgeGroup == 0
        ? rpink
        : themeController.selectedAgeGroup == 1
        ? rblue
        : rgreen;

    return Row(
      children: [
        GetBuilder<UserController>(
          builder: (userController) {
            return Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: accentColor, width: 2),
              ),
              child: userController.avatar != ""
                  ? ClipOval(child: Image.asset(userController.avatar))
                  : const Icon(Icons.person, color: Colors.grey),
            );
          },
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assalam o Alaikum".tr,
              style: TextStyle(
                color: rhint.withOpacity(0.8),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              isLoggedIn ? userName : "Guest User",
              style: TextStyle(
                color: rtext,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildPointsBadge(accentColor),
      ],
    );
  }

  Widget _buildPointsBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            "$points",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(ThemeController themeController) {
    Color accentColor = themeController.selectedAgeGroup == 0
        ? rpink
        : themeController.selectedAgeGroup == 1
        ? rblue
        : rgreen;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 100,
              color: accentColor.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ready to learn and play?".tr,
                        style: TextStyle(
                          color: rtext.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Listen to available duas to UNLOCK remaining duas".tr,
                        style: TextStyle(
                          color: rtext,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.35,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(rpurple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  "assets/images/homeBannerImage.png",
                  width: 80,
                  height: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupSelector(ThemeController themeController) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildAgeTab("Little Kids".tr, 0, themeController, rpink),
          const SizedBox(width: 12),
          _buildAgeTab("Older Kids".tr, 1, themeController, rblue),
          const SizedBox(width: 12),
          _buildAgeTab("Grown ups".tr, 2, themeController, rgreen),
        ],
      ),
    );
  }

  Widget _buildAgeTab(
    String title,
    int index,
    ThemeController themeController,
    Color color,
  ) {
    bool isSelected = themeController.selectedAgeGroup == index;
    return InkWell(
      onTap: () => themeController.setSelectedAgeGroup(index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                  ),
                ],
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? rbluedark : rtext,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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

class _CategoryTileState extends State<CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        Get.to(
          CategoryDetailScreen(widget.categoryModel, widget.color),
          transition: Transition.cupertino,
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Slightly more subtle
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: widget.color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10), // More compact
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  widget.categoryModel.logo,
                  width: 28, // Smaller icon for better balance
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.category_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.categoryModel.getName(
                  Get.find<UserController>().selectedLanguage,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: rbluedark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Refined font size
                  height: 1.1,
                ),
              ).paddingSymmetric(horizontal: 6),
            ],
          ),
        ),
      ),
    );
  }
}
