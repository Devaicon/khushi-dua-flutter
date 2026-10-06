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
import '../subSettings/azkarReminderSettings.dart';
import '../../models/categoryModel.dart';
import 'categoryDetailScreen.dart';
import '../../controllers/notificationController.dart';
import '../../widgets/donateCard.dart';
import '../../widgets/profileAvatar.dart';
import 'notifications.dart';
import '../../widgets/salahBanner.dart';
import '../../widgets/skeleton.dart';

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
                  // Every row above the grid shares one horizontal gutter and
                  // one gap, set here rather than by each widget.
                  _section(
                    FadeInAnimationTTB(
                      delay: 1,
                      child: _buildHeader(themeController),
                    ),
                    top: AppSpace.lg,
                  ),
                  // SalahBanner renders nothing outside its window, so it
                  // carries its own gap instead of leaving an empty one.
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      child: SalahBanner(topGap: AppSpace.lg),
                    ),
                  ),
                  _section(const DonateCard()),
                  _section(_buildAzkarCard()),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: AppSpace.lg),
                    sliver: SliverToBoxAdapter(
                      child: _buildAgeGroupSelector(themeController),
                    ),
                  ),

                  // Category Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.lg,
                    ),
                    sliver:
                        categoryController.isLoading &&
                            filteredCategories.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _CategoryGridSkeleton(),
                          )
                        : SliverGrid(
                            gridDelegate: _gridDelegate,
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final category = filteredCategories[index];
                              return CategoryTile(
                                colors[index % colors.length],
                                category,
                                ageGroup: themeController.selectedAgeGroup,
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

  /// One row of the home screen: the shared gutter, and [top] spacing from
  /// the row above.
  Widget _section(Widget child, {double top = AppSpace.lg}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, top, AppSpace.lg, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }

  Widget _buildHeader(ThemeController themeController) {
    return GetBuilder<UserController>(
      builder: (userController) {
        return Row(
          children: [
            const ProfileAvatar(size: 52),
            const SizedBox(width: AppSpace.md),
            // Expanded, so a long name ellipsises instead of pushing the bell
            // off the screen.
            Expanded(
              child: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: rtext,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            const _InboxBell(),
          ],
        );
      },
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

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  crossAxisSpacing: AppSpace.md,
  mainAxisSpacing: AppSpace.md,
  childAspectRatio: 0.82,
);

/// Stands in for the category grid until the first content load finishes.
class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
        itemCount: 9,
        itemBuilder: (context, index) =>
            const SkeletonBox(radius: AppRadius.card),
      ),
    );
  }
}

class CategoryTile extends StatefulWidget {
  final Color color;
  final CategoryModel categoryModel;

  /// The home screen's selected age group, which sets the tile's palette.
  final int ageGroup;

  const CategoryTile(
    this.color,
    this.categoryModel, {
    super.key,
    this.ageGroup = 0,
  });

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
    _controller = AnimationController(vsync: this, duration: AppMotion.fast);
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
          decoration: CategoryPalette.tileDecoration(
            widget.color,
            widget.ageGroup,
          ),
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
                    color: CategoryPalette.contentColor(
                      widget.ageGroup,
                    ).withValues(alpha: 0.7),
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
                style: TextStyle(
                  color: CategoryPalette.contentColor(widget.ageGroup),
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

/// Opens the announcements inbox, with a badge for anything not yet seen.
/// The inbox used to be a tab of its own.
class _InboxBell extends StatelessWidget {
  const _InboxBell();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      builder: (inbox) {
        final unread = inbox.unreadCount;
        return InkWell(
          onTap: () => Get.to(
            () => const NotificationScreen(),
            transition: Transition.rightToLeft,
          ),
          borderRadius: AppRadius.pillAll,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: AppSurface.card,
                  shape: BoxShape.circle,
                  boxShadow: AppElevation.card,
                ),
                child: Icon(
                  unread > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: rbluedark,
                  size: 22,
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: AppRadius.pillAll,
                      border: Border.all(color: AppSurface.card, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? "9+" : "$unread",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
