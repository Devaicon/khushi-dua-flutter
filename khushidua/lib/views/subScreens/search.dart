import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import '../../constants/colors.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text("Search".tr)),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                style: const TextStyle(
                  color: rbluedark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search for Duas...".tr,
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: rbluedark,
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _searchController.clear(),
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

          // Results List
          Expanded(
            child: filteredSubCategories.isEmpty
                ? Center(
                    child: Text(
                      "No results found".tr,
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredSubCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = filteredSubCategories[index];
                      return InkWell(
                        onTap: () {
                          if (Get.find<ThemeController>().selectedAgeGroup ==
                              0) {
                            Get.to(
                              ImageScreen(subCategoryModel: subCategory),
                              transition: Transition.fadeIn,
                            );
                          } else {
                            Get.to(OpenDuasScreen(subCategory));
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: rbluedark.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: rbluedark,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  subCategory.getName(
                                    Get.find<UserController>().selectedLanguage,
                                  ),
                                  style: const TextStyle(
                                    color: rblack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
