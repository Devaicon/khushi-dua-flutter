import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/userController.dart';
import '../../animations/fadeInAnimationBTT.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../helpers/sectionProgress.dart';
import '../../models/categoryModel.dart';
import '../../models/duaModel.dart';
import '../../models/subCategoryModel.dart';
import '../openDuasScreen.dart';
import '../../widgets/listenedHelp.dart';

/// A category's sections, each with how many duas it holds and, for a
/// logged-in reader, how many of them they have listened to.
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel categoryModel;
  final Color color;

  const CategoryDetailScreen(this.categoryModel, this.color, {super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  static const double _headerHeight = 210;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CategoryController>().getSubCategories(widget.categoryModel);
    });
  }

  /// The category colour laid over the page, so the header matches the home
  /// tiles' light fill.
  Color get _tint =>
      Color.alphaBlend(widget.color.withValues(alpha: 0.3), AppSurface.page);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      // Listening to a dua writes readDuas on the user document, which the
      // live snapshot pushes into UserController; rebuilding on it is what
      // makes newly unlocked sections appear without leaving the screen.
      body: GetBuilder<UserController>(
        builder: (userController) => GetBuilder<DuaController>(
          builder: (duaController) => GetBuilder<CategoryController>(
            builder: (categoryController) {
              // Until the post-frame load runs, the controller still holds
              // the previously opened category's sections.
              final subCategories = categoryController.filteredSubCategories
                  .where((s) => s.categoryId == widget.categoryModel.id)
                  .toList();
              final ageGroup = Get.find<ThemeController>().selectedAgeGroup;
              final userModel = userController.userModel;
              final listened = (userModel?.readDuas ?? const <String>[])
                  .toSet();
              final progress = SectionProgress.compute(
                sectionIds: [for (final sub in subCategories) sub.id],
                allDuas: duaController.allDuas,
                listenedDuaIds: listened,
                ageGroup: ageGroup,
                // Guests and members see every section.
                restricted: userModel != null && !userModel.isMember,
              );

              final stats = [
                for (final sub in subCategories)
                  _SectionStats.of(duaController.duasFor(sub.id), listened),
              ];
              final totalDuas = stats.fold<int>(0, (n, s) => n + s.total);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(userController.selectedLanguage, progress),
                  SliverToBoxAdapter(
                    child: _buildSummary(
                      sectionCount: subCategories.length,
                      duaCount: totalDuas,
                      progress: progress,
                    ),
                  ),
                  if (subCategories.isEmpty)
                    SliverToBoxAdapter(child: _buildEmpty())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.sm,
                        AppSpace.lg,
                        AppSpace.xxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return FadeInAnimationBTT(
                            delay: 0.05 * index,
                            child: _SectionTile(
                              color: widget.color,
                              subCategory: subCategories[index],
                              number: index + 1,
                              stats: stats[index],
                              showListened: userModel != null,
                              isUnlocked: progress.isUnlocked(index),
                              onLockedTap: () =>
                                  showSectionUnlockHelp(progress),
                            ),
                          );
                        }, childCount: subCategories.length),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// A tinted header with the category's artwork that collapses into a plain
  /// title bar on scroll.
  Widget _buildHeader(String language, SectionProgress progress) {
    final name = widget.categoryModel.getName(language);
    return SliverAppBar(
      pinned: true,
      expandedHeight: _headerHeight,
      backgroundColor: _tint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: kAppOverlayStyle,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: rbluedark),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (progress.restricted)
          IconButton(
            tooltip: "How to unlock sections".tr,
            icon: Icon(Icons.info_outline_rounded, color: rbluedark),
            onPressed: () => showSectionUnlockHelp(progress),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        expandedTitleScale: 1.3,
        titlePadding: const EdgeInsetsDirectional.only(
          start: 56,
          end: 56,
          bottom: 16,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: rbluedark,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -24,
              top: -12,
              child: Icon(
                Icons.auto_awesome,
                size: 140,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + AppSpace.lg,
                bottom: 56,
              ),
              child: Center(
                child: Hero(
                  tag: 'category_logo_${widget.categoryModel.id}',
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Image.network(
                      widget.categoryModel.logo,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_rounded,
                        size: 44,
                        color: widget.color.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Counts under the header, and while sections are still locked, how far
  /// the reader is from opening them.
  Widget _buildSummary({
    required int sectionCount,
    required int duaCount,
    required SectionProgress progress,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _InfoChip(
                icon: Icons.layers_rounded,
                label: sectionCount == 1
                    ? "1 section".tr
                    : "@count sections".trParams({'count': '$sectionCount'}),
                color: widget.color,
              ),
              _InfoChip(
                icon: Icons.menu_book_rounded,
                label: duaCountLabel(duaCount),
                color: widget.color,
              ),
            ],
          ),
          if (progress.restricted && !progress.allUnlocked) ...[
            const SizedBox(height: AppSpace.md),
            _UnlockCard(color: widget.color, progress: progress),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: AppText.onPageMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            "No sections available yet".tr,
            style: TextStyle(color: AppText.onPageMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// How many duas a section holds and how many the reader has listened to.
class _SectionStats {
  const _SectionStats(this.total, this.listened);

  factory _SectionStats.of(List<DuaModel> duas, Set<String> listenedIds) {
    var listened = 0;
    for (final dua in duas) {
      if (listenedIds.contains(dua.id)) listened++;
    }
    return _SectionStats(duas.length, listened);
  }

  final int total;
  final int listened;

  bool get isComplete => total > 0 && listened >= total;
  double get fraction => total == 0 ? 0 : listened / total;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppSurface.card,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color.ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: rtext,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress towards unlocking the rest of the category, always visible while
/// something is locked rather than a tip that disappears once dismissed.
class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.color, required this.progress});

  final Color color;
  final SectionProgress progress;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.freeSectionCount == 0
        ? 1.0
        : progress.completedFreeSections / progress.freeSectionCount;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: plainCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open_rounded, size: 18, color: color.ink),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  "Unlock more sections".tr,
                  style: TextStyle(
                    color: rtext,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => showSectionUnlockHelp(progress),
                child: Text(
                  "How it works".tr,
                  style: TextStyle(
                    color: color.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            sectionUnlockSummary(progress),
            style: TextStyle(
              color: rtext.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.2),
              color: color.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "@done of @total sections complete".trParams({
              'done': '${progress.completedFreeSections}',
              'total': '${progress.freeSectionCount}',
            }),
            style: TextStyle(color: AppText.onPageMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// One section: its number, name, dua count and listening progress.
/// Complete sections swap the number for a check; locked ones are muted.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.color,
    required this.subCategory,
    required this.number,
    required this.stats,
    required this.showListened,
    required this.isUnlocked,
    required this.onLockedTap,
  });

  final Color color;
  final SubCategoryModel subCategory;
  final int number;
  final _SectionStats stats;
  final bool showListened;
  final bool isUnlocked;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final name = subCategory.getName(
      Get.find<UserController>().selectedLanguage,
    );
    final ink = color.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: isUnlocked
              ? () => Get.to(() => OpenDuasScreen(subCategory, color: color))
              : onLockedTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpace.md + 2),
            decoration: BoxDecoration(
              color: isUnlocked ? AppSurface.card : AppSurface.raised,
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: isUnlocked
                    ? color.withValues(alpha: 0.45)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isUnlocked ? AppElevation.card : null,
            ),
            child: Row(
              children: [
                _buildLeading(ink),
                const SizedBox(width: AppSpace.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnlocked ? rtext : AppText.onPageMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _meta(),
                        style: TextStyle(
                          color: AppText.onPageMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (isUnlocked && showListened && stats.total > 0) ...[
                        const SizedBox(height: AppSpace.sm),
                        ClipRRect(
                          borderRadius: AppRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: stats.fraction,
                            minHeight: 4,
                            backgroundColor: color.withValues(alpha: 0.18),
                            color: ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(
                  isUnlocked ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  color: isUnlocked ? ink : AppText.onPageMuted,
                  size: isUnlocked ? 24 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _meta() {
    final count = duaCountLabel(stats.total);
    if (!showListened || stats.total == 0) return count;
    return "$count  ·  ${"@done of @total listened".trParams({'done': '${stats.listened}', 'total': '${stats.total}'})}";
  }

  Widget _buildLeading(Color ink) {
    final done = isUnlocked && stats.isComplete;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? ink
            : isUnlocked
            ? color.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
          : Text(
              '$number',
              style: TextStyle(
                color: isUnlocked ? ink : AppText.onPageMuted,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
    );
  }
}
