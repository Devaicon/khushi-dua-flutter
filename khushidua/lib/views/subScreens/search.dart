import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import '../../constants/colors.dart';
import '../../constants/theme.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../controllers/themeController.dart';
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

    setState(() {
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
      appBar: AppBar(
        title: Text(
          "Explore Duas".tr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: rbluedark),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                style: const TextStyle(
                  color: rbluedark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search for Duas...".tr,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  prefixIcon: const Icon(
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
              padding: const EdgeInsets.symmetric(horizontal: 15),
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
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
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

          const SizedBox(height: 10),

          // Results Section
          Expanded(
            child:
                filteredSubCategories.isEmpty &&
                    _searchController.text.isNotEmpty
                ? _buildEmptyState()
                : _searchController.text.isEmpty
                ? _buildInitialState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredSubCategories.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final subCategory = filteredSubCategories[index];
                      final categoryName =
                          categoryController.allCategories
                              .firstWhereOrNull(
                                (c) => c.id == subCategory.categoryId,
                              )
                              ?.getName(userController.selectedLanguage) ??
                          "";

                      return _buildResultTile(subCategory, categoryName);
                    },
                  ),
          ),
        ],
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.xl),
            physics: const BouncingScrollPhysics(),
            children: [
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
              const SizedBox(height: AppSpace.lg),
              const DonateCard(),
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
          style: const TextStyle(
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

  Widget _buildResultTile(SubCategoryModel subCategory, String categoryName) {
    return FadeInAnimationBTT(
      delay: 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            onTap: () => Get.to(() => OpenDuasScreen(subCategory)),
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
                    child: const Icon(
                      Icons.book_rounded,
                      color: Colors.white,
                      size: 26,
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
                          style: const TextStyle(
                            color: rbluedark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (categoryName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              categoryName,
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
                    child: const Icon(
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
