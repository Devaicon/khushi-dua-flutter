import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/categoryController.dart';
import '../controllers/contentController.dart';
import '../models/auditEntry.dart';
import '../models/categoryModel.dart';
import '../models/subCategoryModel.dart';
import '../models/translatedItem.dart';
import 'auditService.dart';
import 'duaService.dart';
import 'storageService.dart';

/// Reads and writes categories and their sections (subcategories).
///
/// Throws on failure; screens decide what to say and where to go.
class CategoryService {
  final CategoryController _controller = Get.find<CategoryController>();

  void listen() {
    categoryRef.snapshots().listen((event) {
      for (final change in event.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _controller.removeCategory(change.doc.id);
        } else if (change.doc.data() != null) {
          _controller.putCategory(
              CategoryModel.fromMap({...change.doc.data()!, 'id': change.doc.id}));
        }
      }
      _controller.markLoaded();
    }, onError: (Object e) => debugPrint('Categories unavailable: $e'));
    subCategoryRef.snapshots().listen((event) {
      for (final change in event.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _controller.removeSection(change.doc.id);
        } else if (change.doc.data() != null) {
          _controller.putSection(SubCategoryModel.fromMap(
              {...change.doc.data()!, 'id': change.doc.id}));
        }
      }
      _controller.markLoaded();
    }, onError: (Object e) => debugPrint('Sections unavailable: $e'));
  }

  static (CollectionReference<Map<String, dynamic>>, String, String) _where(
      TranslatedItem item) {
    return item is CategoryModel
        ? (categoryRef, 'Category', 'categoryLogo')
        : (subCategoryRef, 'SubCategory', 'subCategoryImage');
  }

  /// Saves a category or section, first uploading a newly picked [image].
  /// A new one (empty id) gets an id and goes to the end of its list.
  Future<void> save(TranslatedItem item, {html.File? image}) async {
    final (ref, collection, imageName) = _where(item);
    final isNew = item.id.isEmpty;
    if (isNew) {
      item.id = ref.doc().id;
      item.createdAt = DateTime.now();
    }
    final before = isNew ? null : (await ref.doc(item.id).get()).data();
    if (image != null) {
      item.imageUrl =
          await StorageService.upload(image, '${item.id}/$imageName');
    }
    item.updatedAt = DateTime.now();
    final after = item.toMap();
    await ref.doc(item.id).set(after, SetOptions(merge: !isNew));
    await AuditService.record(
      action: isNew ? AuditAction.create : AuditAction.update,
      collection: collection,
      docId: item.id,
      label: item.title,
      before: before,
      after: after,
    );
    Get.find<ContentController>().contentChanged();
  }

  /// Deletes a category or section. Callers make sure it is empty first:
  /// a category's sections, or a section's duas, would be left orphaned.
  Future<void> delete(TranslatedItem item) async {
    final (ref, collection, _) = _where(item);
    final before = (await ref.doc(item.id).get()).data();
    await ref.doc(item.id).delete();
    await AuditService.record(
      action: AuditAction.delete,
      collection: collection,
      docId: item.id,
      label: item.title,
      before: before,
    );
    Get.find<ContentController>().contentChanged();
  }

  /// Saves the order of [ordered], all categories or one category's sections.
  Future<void> reorder(List<TranslatedItem> ordered, {required String label}) {
    if (ordered.isEmpty) return Future.value();
    final (ref, collection, _) = _where(ordered.first);
    return reorderDocs(
      ref,
      collection,
      [for (final item in ordered) (item.id, item.order)],
      label: label,
      apply: (i) => ordered[i].order = i,
    );
  }
}
