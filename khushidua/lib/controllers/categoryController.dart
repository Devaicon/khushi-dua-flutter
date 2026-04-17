import 'package:get/get.dart';
import 'package:khushidua/controllers/themeController.dart';

import '../models/categoryModel.dart';
import '../models/subCategoryModel.dart';
import '../services/categoryService.dart';

class CategoryController extends GetxController {
  final List<CategoryModel> _allCategories = [];
  final List<SubCategoryModel> _allSubCategories = [];
  List<SubCategoryModel> _filteredSubCategories = [];

  List<CategoryModel> get allCategories => _allCategories;

  List<SubCategoryModel> get allSubCategories => _allSubCategories;

  List<SubCategoryModel> get filteredSubCategories => _filteredSubCategories;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  setLoading(bool value) {
    _isLoading = value;
    update();
  }

  getAllCategories() {
    CategoryService().getAllCategories();
  }

  getAllSubCategories() {
    CategoryService().getAllSubCategories();
  }

  final List<CategoryModel> _filteredCategories = [];

  List<CategoryModel> get filteredCategories => _filteredCategories;

  addCategoryToList(CategoryModel categoryModel) {
    int existingIndex = _allCategories.indexWhere(
      (cat) => cat.id == categoryModel.id,
    );

    if (existingIndex == -1) {
      _allCategories.add(categoryModel);
    } else {
      _allCategories[existingIndex] = categoryModel;
    }
    _allCategories.sort((a, b) => a.order.compareTo(b.order));
    _refreshFilteredCategories();
  }

  void _refreshFilteredCategories() {
    final themeController = Get.find<ThemeController>();
    final ageGroup = themeController.selectedAgeGroup;

    _filteredCategories.clear();
    _filteredCategories.addAll(
      _allCategories.where((category) {
        if (!category.isEnabled) return false;

        // Basic age group filtering
        bool isAllowed = false;
        if (ageGroup == 0) {
          isAllowed = category.littleKids;
        } else if (ageGroup == 1) {
          isAllowed = category.olderKids;
        } else {
          isAllowed = category.grownUps;
        }

        if (!isAllowed) return false;

        // Special exclusion for little kids
        if (ageGroup == 0) {
          final categoryName = category.english.toLowerCase();
          if (categoryName.contains('family') &&
              categoryName.contains('wedding')) {
            return false;
          }
        }

        return true;
      }),
    );

    update();
  }

  CategoryModel? _lastCategory;

  getSubCategories(CategoryModel categoryModel) {
    _lastCategory = categoryModel;
    _refreshFilteredSubCategories();
  }

  void refreshAll() {
    _refreshFilteredCategories();
    _refreshFilteredSubCategories();
  }

  void _refreshFilteredSubCategories() {
    if (_lastCategory == null) return;

    final themeController = Get.find<ThemeController>();
    final ageGroup = themeController.selectedAgeGroup;

    _filteredSubCategories = _allSubCategories.where((element) {
      if (element.categoryId != _lastCategory!.id || !element.isEnabled) {
        return false;
      }

      // Filter by age group availability
      if (ageGroup == 0) return element.littleKids;
      if (ageGroup == 1) return element.olderKids;
      if (ageGroup == 2) return element.grownUps;
      return true;
    }).toList();

    _filteredSubCategories.sort((a, b) => a.order.compareTo(b.order));
    update();
  }

  addSubCategoryToList(SubCategoryModel subCategoryModel) {
    int existingIndex = _allSubCategories.indexWhere(
      (cat) => cat.id == subCategoryModel.id,
    );

    if (existingIndex == -1) {
      _allSubCategories.add(subCategoryModel);
    } else {
      _allSubCategories[existingIndex] = subCategoryModel;
    }
    _allSubCategories.sort((a, b) => a.order.compareTo(b.order));

    // Auto-refresh filtered list if the new/updated subcategory belongs to it
    _refreshFilteredSubCategories();
  }
}
