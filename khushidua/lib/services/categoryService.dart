import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/models/subCategoryModel.dart';

import '../models/categoryModel.dart';

class CategoryService {
  final CategoryController _categoryController = Get.find<CategoryController>();

  getAllCategories() async {
    categoryRef.snapshots().listen((event) {
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _categoryController.addCategoryToList(
            CategoryModel.fromMap(element.doc.data()!),
          );
        }
      });
    });
  }

  getAllSubCategories() async {
    subCategoryRef.snapshots().listen((event) {
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _categoryController.addSubCategoryToList(
            SubCategoryModel.fromMap(element.doc.data()!),
          );
        }
      });
    });
  }
}
