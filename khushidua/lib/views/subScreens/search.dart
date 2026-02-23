import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import '../../constants/colors.dart';

import '../../animations/fadeInAnimationBTT.dart';
import '../../controllers/themeController.dart';
import '../../controllers/userController.dart';
import '../../models/subCategoryModel.dart';
import '../imageScreen.dart';
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
    String selectedLanguage = Get.find<UserController>().selectedLanguage;
    setState(() {
      filteredSubCategories = Get.find<CategoryController>().allSubCategories
          .where(
            (subCategory) => subCategory
                .getName(selectedLanguage)
                .toLowerCase()
                .contains(query),
          )
          .toList();
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
      backgroundColor: const Color(0xffF8F9FE),
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

  Widget _buildInitialState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: rbluedark.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Search anything...".tr,
            style: TextStyle(
              color: rbluedark.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            onTap: () {
              if (Get.find<ThemeController>().selectedAgeGroup == 0) {
                Get.to(
                  ImageScreen(subCategoryModel: subCategory),
                  transition: Transition.fadeIn,
                );
              } else {
                Get.to(OpenDuasScreen(subCategory));
              }
            },
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
