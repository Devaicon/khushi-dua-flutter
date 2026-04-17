import 'package:get/get.dart';
import 'package:khushidua/models/subCategoryModel.dart';
import 'package:khushidua/services/duaService.dart';

import '../models/duaModel.dart';

class DuaController extends GetxController {
  final List<DuaModel> _allDuas = [];
  List<DuaModel> _filteredDuas = [];
  List<DuaModel> get allDuas => _allDuas;
  List<DuaModel> get filteredDuas => _filteredDuas;

  String? _lastSubCategoryId;

  int _getVerseCount(DuaModel dua) {
    if (dua.arabic.isEmpty) return 0;
    return dua.arabic
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
  }

  void _sortDuas(List<DuaModel> list) {
    list.sort((a, b) {
      // Primary: Original Order field from Firebase
      if (a.order != b.order) {
        return a.order.compareTo(b.order);
      }

      // Secondary: Shortest first (verse count)
      int countA = _getVerseCount(a);
      int countB = _getVerseCount(b);
      if (countA != countB) {
        return countA.compareTo(countB);
      }

      // Tertiary: ID for stability
      return a.id.compareTo(b.id);
    });
  }

  addDuaToList(DuaModel duaModel) {
    int existingIndex = _allDuas.indexWhere((cat) => cat.id == duaModel.id);

    if (existingIndex == -1) {
      _allDuas.add(duaModel);
    } else {
      _allDuas[existingIndex] = duaModel;
    }

    _sortDuas(_allDuas);

    // If we're currently viewing a subcategory, refresh the filtered list
    if (_lastSubCategoryId != null) {
      refreshFilteredDuas();
    }

    update();
  }

  getAllDuas() {
    DuaService().getAllDuas();
  }

  getFilteredDuas(SubCategoryModel subCategoryModel) {
    _lastSubCategoryId = subCategoryModel.id;
    refreshFilteredDuas();
    update();
  }

  void refreshFilteredDuas() {
    if (_lastSubCategoryId == null) return;

    _filteredDuas = _allDuas.where((dua) {
      return dua.subCategoryIds.contains(_lastSubCategoryId);
    }).toList();

    _sortDuas(_filteredDuas);
  }
}
