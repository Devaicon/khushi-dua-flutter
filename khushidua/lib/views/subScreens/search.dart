import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../controllers/duaController.dart';
import '../../controllers/themeController.dart';
import '../../helpers/duaNumberSearch.dart';
import '../../controllers/userController.dart';
import '../../models/subCategoryModel.dart';
import '../../widgets/donateCard.dart';
import '../openDuasScreen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SubCategoryModel> filteredSubCategories = [];

  /// Sections holding the dua asked for by number ("morning 3"), each with
  /// how many duas it has. Shown instead of the name matches when not empty.
  List<({SubCategoryModel section, int number, int total})> _numberHits = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSubCategories);
  }

  void _filterSubCategories() {
    String query = _searchController.text.toLowerCase();
    final categoryController = Get.find<CategoryController>();
    final userController = Get.find<UserController>();
    String selectedLanguage = userController.selectedLanguage;

    final numberQuery = DuaNumberQuery.parse(query);
    final hits = numberQuery == null
        ? <({SubCategoryModel section, int number, int total})>[]
        : _numberSearch(numberQuery, categoryController, selectedLanguage);

    setState(() {
      _numberHits = hits;
      filteredSubCategories = categoryController.allSubCategories.where((
        subCategory,
      ) {
        if (!subCategory.isEnabled) return false;

        // Search in subCategory name
        bool matchesName = subCategory
            .getName(selectedLanguage)
            .toLowerCase()
            .contains(query);

        // Search in category name
        final category = categoryController.allCategories.firstWhereOrNull(
          (c) => c.id == subCategory.categoryId,
        );
        bool matchesCategory =
            category?.getName(selectedLanguage).toLowerCase().contains(query) ??
            false;

        return matchesName || matchesCategory;
      }).toList();
    });
  }

  /// Every section the reader can open whose name or category matches
  /// [query]'s text and that has a dua at [query]'s number.
  List<({SubCategoryModel section, int number, int total})> _numberSearch(
    DuaNumberQuery query,
    CategoryController categories,
    String language,
  ) {
    final duas = Get.find<DuaController>();
    final hits = <({SubCategoryModel section, int number, int total})>[];
    for (final section in _browseList(categories)) {
      if (query.text.isNotEmpty) {
        final category = categories.allCategories.firstWhereOrNull(
          (c) => c.id == section.categoryId,
        );
        final names = [
          section.getName(language),
          category?.getName(language) ?? '',
        ].join(' ').toLowerCase();
        if (!names.contains(query.text)) continue;
      }
      final total = duas.duasFor(section.id).length;
      if (total >= query.number) {
        hits.add((section: section, number: query.number, total: total));
      }
    }
    return hits;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: AppSurface.page,
      body: Column(
        children: [
          // The same title, size and gutter as the other tabs' headers.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Explore Duas".tr,
                    style: TextStyle(
                      color: rtext,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const DonationPlacement(
                  placement: 'searchPill',
                  child: _DonatePill(),
                ),
              ],
            ),
          ),
          // Search Bar Container
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.xs,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppSurface.card,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: rbluedark.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                onChanged: (_) => _filterSubCategories(),
                style: TextStyle(color: rbluedark, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search by name or dua number".tr,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: rbluedark,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterSubCategories();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          // Categories Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg - 5),
              scrollDirection: Axis.horizontal,
              itemCount: categoryController.allCategories.length,
              itemBuilder: (context, index) {
                final category = categoryController.allCategories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 10,
                  ),
                  child: ActionChip(
                    label: Text(
                      category.getName(userController.selectedLanguage),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      _searchController.text = category.getName(
                        userController.selectedLanguage,
                      );
                      _filterSubCategories();
                    },
                    backgroundColor: AppSurface.card,
                    surfaceTintColor: AppSurface.card,
                    elevation: 2,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpace.xs),

          // Results Section
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildInitialState()
                : _numberHits.isNotEmpty
                ? _buildResults([
                    for (final hit in _numberHits)
                      _buildResultTile(
                        hit.section,
                        _categoryName(hit.section, categoryController),
                        number: hit.number,
                        total: hit.total,
                      ),
                  ])
                : filteredSubCategories.isEmpty
                ? _buildEmptyState()
                : _buildResults([
                    for (final subCategory in filteredSubCategories)
                      _buildResultTile(
                        subCategory,
                        _categoryName(subCategory, categoryController),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }

  String _categoryName(SubCategoryModel section, CategoryController c) =>
      c.allCategories
          .firstWhereOrNull((cat) => cat.id == section.categoryId)
          ?.getName(Get.find<UserController>().selectedLanguage) ??
      "";

  /// The donation card leads every list, just under the quick filters, and
  /// scrolls away with it.
  Widget get _donateCard => const DonationPlacement(
    placement: 'search',
    child: Padding(
      padding: EdgeInsets.only(bottom: AppSpace.lg),
      child: DonateCard(),
    ),
  );

  Widget _buildResults(List<Widget> tiles) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xl,
      ),
      physics: const BouncingScrollPhysics(),
      children: [_donateCard, ...tiles],
    );
  }

  /// Before anything is typed, the screen lists sections to browse rather
  /// than sitting empty: [_pageSize] at a time, in the home screen's order.
  static const int _pageSize = 10;
  int _browseCount = _pageSize;

  /// The sections the reader can see for their age group, in category order
  /// and then section order — the order they appear on the home screen.
  List<SubCategoryModel> _browseList(CategoryController categories) {
    final ageGroup = Get.find<ThemeController>().selectedAgeGroup;
    final categoryRank = {
      for (final (i, c) in categories.filteredCategories.indexed) c.id: i,
    };
    return categories.allSubCategories.where((s) {
      if (!s.isEnabled || !categoryRank.containsKey(s.categoryId)) {
        return false;
      }
      return switch (ageGroup) {
        0 => s.littleKids,
        1 => s.olderKids,
        _ => s.grownUps,
      };
    }).toList()..sort((a, b) {
      final byCategory = categoryRank[a.categoryId]!.compareTo(
        categoryRank[b.categoryId]!,
      );
      return byCategory != 0 ? byCategory : a.order.compareTo(b.order);
    });
  }

  Widget _buildInitialState() {
    // Content and the age group both load or change after this screen is
    // built, so the list follows them.
    return GetBuilder<ThemeController>(
      builder: (_) => GetBuilder<CategoryController>(
        builder: (categoryController) {
          final language = Get.find<UserController>().selectedLanguage;
          final all = _browseList(categoryController);
          final shown = all.take(_browseCount).toList();
          final hasMore = all.length > shown.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xl,
            ),
            physics: const BouncingScrollPhysics(),
            children: [
              _donateCard,
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: Text(
                  "Browse duas".tr,
                  style: TextStyle(
                    color: AppText.onPageMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final subCategory in shown)
                _buildResultTile(
                  subCategory,
                  categoryController.allCategories
                          .firstWhereOrNull(
                            (c) => c.id == subCategory.categoryId,
                          )
                          ?.getName(language) ??
                      "",
                ),
              if (hasMore)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _browseCount += _pageSize),
                    style: TextButton.styleFrom(foregroundColor: rbluedark),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text("Load more".tr),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 50,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "No results found".tr,
          style: TextStyle(
            color: rbluedark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Try different keywords".tr,
          style: TextStyle(color: Colors.grey.withOpacity(0.6)),
        ),
      ],
    );
  }

  /// A section to open. With [number], it is a hit for a dua number: the
  /// number leads the tile, and opening it scrolls to that dua.
  Widget _buildResultTile(
    SubCategoryModel subCategory,
    String categoryName, {
    int? number,
    int? total,
  }) {
    final subtitle = [
      if (number != null)
        "Dua @index of @total".trParams({
          'index': '$number',
          'total': '$total',
        }),
      if (categoryName.isNotEmpty) categoryName,
    ].join("  •  ");
    return FadeInAnimationBTT(
      delay: 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppSurface.card,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // Straight to the duas; a kids' section shows its illustration
            // at the top of that list.
            onTap: () => Get.to(
              () => OpenDuasScreen(subCategory, scrollToNumber: number),
            ),
            borderRadius: BorderRadius.circular(25),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffEEB6A3), Color(0xffC3CCF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: number == null
                        ? const Icon(
                            Icons.book_rounded,
                            color: Colors.white,
                            size: 26,
                          )
                        : Text(
                            '$number',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subCategory.getName(
                            Get.find<UserController>().selectedLanguage,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: rbluedark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                color: rbluedark.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: rbluedark.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: rbluedark,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small Donate button in the header, for readers who never scroll down
/// to the card.
class _DonatePill extends StatelessWidget {
  const _DonatePill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openDonate,
        borderRadius: AppRadius.pillAll,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            gradient: AppGradient.forSeed(kDonateSeed),
            borderRadius: AppRadius.pillAll,
            boxShadow: AppElevation.card,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Donate".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
