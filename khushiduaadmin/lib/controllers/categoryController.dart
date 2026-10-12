import 'package:get/get.dart';

import '../models/categoryModel.dart';
import '../models/subCategoryModel.dart';
import '../services/categoryService.dart';

/// Every category and section (subcategory), kept live.
class CategoryController extends GetxController {
  final List<CategoryModel> _allCategories = [];
  List<CategoryModel> get allCategories => _allCategories;

  final List<SubCategoryModel> _allSubCategories = [];
  List<SubCategoryModel> get allSubCategories => _allSubCategories;

  bool _loaded = false;
  bool get loaded => _loaded;

  void listen() => CategoryService().listen();

  CategoryModel? categoryById(String id) =>
      _allCategories.firstWhereOrNull((c) => c.id == id);

  SubCategoryModel? sectionById(String id) =>
      _allSubCategories.firstWhereOrNull((s) => s.id == id);

  /// A category's sections, in the app's order.
  List<SubCategoryModel> sectionsOf(String categoryId) =>
      [for (final s in _allSubCategories) if (s.categoryId == categoryId) s];

  /// "Salah › Before Salah", for a section id.
  String sectionPath(String sectionId) {
    final section = sectionById(sectionId);
    if (section == null) return 'Missing section';
    final category = categoryById(section.categoryId);
    return '${category?.title ?? 'No category'} › ${section.title}';
  }

  void putCategory(CategoryModel category) {
    final i = _allCategories.indexWhere((c) => c.id == category.id);
    i == -1 ? _allCategories.add(category) : _allCategories[i] = category;
  }

  void removeCategory(String id) =>
      _allCategories.removeWhere((c) => c.id == id);

  void putSection(SubCategoryModel section) {
    final i = _allSubCategories.indexWhere((s) => s.id == section.id);
    i == -1 ? _allSubCategories.add(section) : _allSubCategories[i] = section;
  }

  void removeSection(String id) =>
      _allSubCategories.removeWhere((s) => s.id == id);

  void markLoaded() {
    _loaded = true;
    int byOrder(dynamic a, dynamic b) {
      final c = (a.order as int).compareTo(b.order as int);
      return c != 0 ? c : (a.id as String).compareTo(b.id as String);
    }

    _allCategories.sort(byOrder);
    _allSubCategories.sort(byOrder);
    update();
  }

  /// Re-sorts after a local reorder, before Firestore echoes it back.
  void resort() => markLoaded();
}
