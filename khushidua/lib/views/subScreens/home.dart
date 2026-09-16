import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/fadeInAnimationTTB.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';
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
      backgroundColor: AppSurface.page,
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
                    ).paddingSymmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                  ),

                  // Premium Banner
                  SliverToBoxAdapter(
                    child: _buildBanner(
                      themeController,
                    ).paddingSymmetric(horizontal: AppSpace.lg),
                  ),

                  // Salah time banner
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.md,
                        AppSpace.lg,
                        0,
                      ),
                      child: SalahBanner(),
                    ),
                  ),

                  // Azkar Reminder
                  SliverToBoxAdapter(
                    child: _buildAzkarCard().paddingOnly(
                      left: AppSpace.lg,
                      right: AppSpace.lg,
                      top: AppSpace.md,
                    ),
                  ),

                  // Age Group Selector
                  SliverToBoxAdapter(
                    child: _buildAgeGroupSelector(
                      themeController,
                    ).paddingSymmetric(vertical: AppSpace.lg),
                  ),

                  // Category Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.sm,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpace.md,
                            mainAxisSpacing: AppSpace.md,
                            childAspectRatio: 0.82,
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
                    color: AppText.onPageMuted,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppGradient.forSeed(accentColor),
        borderRadius: AppRadius.pillAll,
        boxShadow: AppElevation.card,
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
          borderRadius: AppRadius.cardAll,
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
      decoration: cardDecoration(accentColor),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 100,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppText.onSurfaceMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppText.onSurface,
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
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
        final accent = isOn ? rpurple : const Color(0xFF9AA0B4);

        return InkWell(
          onTap: () => Get.to(
            const AzkarReminderSettings(),
            transition: Transition.fade,
          ),
          borderRadius: AppRadius.cardAll,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: cardDecoration(accent),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    isOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: AppText.onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Azkar Reminders".tr,
                        style: const TextStyle(
                          color: AppText.onSurface,
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
                          color: AppText.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppText.onSurfaceMuted,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => themeController.setSelectedAgeGroup(index),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppGradient.forSeed(color)
              : AppGradient.neutral,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppElevation.card,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? AppText.onSurface : AppText.onPageMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
      duration: AppMotion.fast,
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
    // At three columns a tile is roughly a third of the screen, so the
    // artwork gets the space and the label takes what is left.
    final double tileWidth = (MediaQuery.of(context).size.width - 56) / 3;
    final double iconSize = (tileWidth * 0.62).clamp(44.0, 76.0);

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
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: cardDecoration(widget.color),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'category_logo_${widget.categoryModel.id}',
                child: Image.network(
                  widget.categoryModel.logo,
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.category_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: iconSize * 0.8,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              // Long names ellipsize rather than wrapping to a ragged third
              // line, which would push the artwork out of the tile.
              Text(
                widget.categoryModel.getName(
                  Get.find<UserController>().selectedLanguage,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppText.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
