import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';

import '../../controllers/themeController.dart';
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
    setState(() {
      filteredSubCategories = Get.find<CategoryController>().allSubCategories
          .where(
            (subCategory) => subCategory.english.toLowerCase().contains(query),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.blue.withOpacity(0.3),
                prefixIcon: Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                ),
              ),
              style: TextStyle(color: Colors.black),
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
                    itemCount: filteredSubCategories.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          if (Get.find<ThemeController>().selectedAgeGroup ==
                              0) {
                            Get.to(
                              ImageScreen(
                                subCategoryModel: filteredSubCategories[index],
                              ),
                              transition: Transition.fadeIn,
                            );
                          } else {
                            Get.to(
                              OpenDuasScreen(filteredSubCategories[index]),
                            );
                          }
                        },
                        child: ListTile(
                          title: Text(
                            filteredSubCategories[index].english,
                            style: TextStyle(color: Colors.black),
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
