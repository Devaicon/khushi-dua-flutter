import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../controllers/reminderController.dart';
import '../../controllers/homeBannerController.dart';
import '../../models/homeBannerModel.dart';
import '../subSettings/azkarReminderSettings.dart';
import '../../models/categoryModel.dart';
import 'categoryDetailScreen.dart';
import '../../widgets/profileAvatar.dart';
import '../../widgets/salahBanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> colors = [
    Color(0xFF64B5F6), // Blue
    Color(0xFFF06292), // Pink
    Color(0xFF4DB6AC), // Teal
    Color(0xFFFFF176), // Yellow
    Color(0xFFFFB74D), // Orange
    Color(0xFFE57373), // Red
    Color(0xFFAED581), // Light Green
    Color(0xFFBA68C8), // Purple
    Color(0xFF4DD0E1), // Cyan
    Color(0xFF90A4AE), // Blue Grey
    Color(0xFF7986CB), // Indigo
    Color(0xFFFF8A65), // Deep Orange
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
              final filteredCategories = categoryController.filteredCategories;

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

                  // Salah time banner
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: SalahBanner(),
                    ),
                  ),

                  // Azkar Reminder
                  SliverToBoxAdapter(
                    child: _buildAzkarCard().paddingOnly(
                      left: 20,
                      right: 20,
                      top: 12,
                    ),
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
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.05,
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

    return GetBuilder<UserController>(
      builder: (userController) {
        return Row(
          children: [
            const ProfileAvatar(size: 55),
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
                  userController.isLoggedIn
                      ? userController.userName
                      : "Guest User".tr,
                  style: const TextStyle(
                    color: rtext,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildPointsBadge(accentColor, userController.points),
          ],
        );
      },
    );
  }

  Widget _buildPointsBadge(Color accentColor, int userPoints) {
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
            "$userPoints",
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
    return GetBuilder<HomeBannerController>(
      builder: (bannerController) {
        final banner = bannerController.banner;
        final language = Get.find<UserController>().selectedLanguage;

        // Until an admin publishes a banner, keep the copy the app shipped
        // with so the home screen never looks empty.
        final title = banner.hasContent(language)
            ? banner.titleFor(language)
            : "Ready to learn and play?".tr;
        final subtitle = banner.hasContent(language)
            ? banner.subtitleFor(language)
            : "Listen to available duas to UNLOCK remaining duas".tr;

        final content = _bannerBody(themeController, banner, title, subtitle);

        if (!banner.hasLink) return content;

        return InkWell(
          onTap: () => _openBannerLink(banner.linkCategoryId),
          borderRadius: BorderRadius.circular(24),
          child: content,
        );
      },
    );
  }

  /// Opens the category the admin linked the banner to. Does nothing when the
  /// id no longer matches a category, rather than pushing a blank screen.
  void _openBannerLink(String categoryId) {
    final categories = Get.find<CategoryController>().filteredCategories;
    final match = categories.where((c) => c.id == categoryId);
    if (match.isEmpty) return;
    Get.to(
      () => CategoryDetailScreen(match.first, rpurple),
      transition: Transition.rightToLeft,
    );
  }

  Widget _bannerBody(
    ThemeController themeController,
    HomeBannerModel banner,
    String title,
    String subtitle,
  ) {
    Color accentColor = themeController.selectedAgeGroup == 0
        ? rpink
        : themeController.selectedAgeGroup == 1
        ? rblue
        : rgreen;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
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
                        title,
                        style: TextStyle(
                          color: rtext.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: rtext,
                          fontWeight: FontWeight.w900,
                          fontSize: MediaQuery.of(context).size.width < 360
                              ? 14
                              : 18,
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
                // An admin-uploaded image replaces the bundled one; a broken
                // or slow URL falls back to the asset rather than a grey box.
                banner.hasImage
                    ? Image.network(
                        banner.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/images/homeBannerImage.png",
                          width: 80,
                          height: 80,
                        ),
                      )
                    : Image.asset(
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

  /// Entry point for the Azkar reminders. Shows the next reminder time when
  /// they are on, and an invitation to switch them on when they are off.
  Widget _buildAzkarCard() {
    return GetBuilder<ReminderController>(
      builder: (reminder) {
        final isOn = reminder.azkarEnabled;
        final accent = isOn ? rpurple : Colors.grey;

        return InkWell(
          onTap: () => Get.to(
            const AzkarReminderSettings(),
            transition: Transition.fade,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: isOn ? rtext : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Azkar Reminders".tr,
                        style: TextStyle(
                          color: rtext,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOn
                            ? "${reminder.morningTime.format(context)}  •  ${reminder.eveningTime.format(context)}"
                            : "Tap to set morning and evening reminders".tr,
                        style: TextStyle(
                          color: rtext.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: rtext.withOpacity(0.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgeGroupSelector(ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildAgeTab("Little Kids".tr, 0, themeController, rpink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAgeTab("Older Kids".tr, 1, themeController, rblue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildAgeTab("Grown ups".tr, 2, themeController, rgreen),
          ),
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
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth < 360 ? 6 : 10;
    double verticalPadding = screenWidth < 360 ? 10 : 14;
    double fontSize = screenWidth < 360 ? 13 : 16;

    return InkWell(
      onTap: () => themeController.setSelectedAgeGroup(index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
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
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? rbluedark : rtext,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
            ),
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
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth < 360 ? 40 : 52;
    double fontSize = screenWidth < 360 ? 12 : 14;
    double circlePadding = screenWidth < 360 ? 10 : 16;
    double spacing = screenWidth < 360 ? 8 : 12;

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
            color: widget.color.withOpacity(0.3), // More colorful background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'category_logo_${widget.categoryModel.id}',
                child: Image.network(
                  widget.categoryModel.logo,
                  width: iconSize, // Responsive icon size
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.category_rounded,
                    color: Colors.grey,
                    size: iconSize * 0.8,
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Text(
                widget.categoryModel.getName(
                  Get.find<UserController>().selectedLanguage,
                ),
                textAlign: TextAlign.center,
                maxLines: 3, // Allow more lines for full name visibility
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: rbluedark,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize, // Responsive font size
                  height: 1.1,
                ),
              ).paddingSymmetric(horizontal: 4),
            ],
          ),
        ),
      ),
    );
  }
}
