import 'package:get/get.dart';
import 'package:khushidua/models/subCategoryModel.dart';
import 'package:khushidua/services/duaService.dart';

import '../models/duaModel.dart';

class DuaController extends GetxController {
  final List<DuaModel> _allDuas = [];
  List<DuaModel> _filteredDuas = [];
  List<DuaModel> get allDuas => _allDuas;
  List<DuaModel> get filteredDuas => _filteredDuas;

  int _getVerseCount(DuaModel dua) {
    // Veruses are typically separated by newlines in the Arabic text
    if (dua.arabic.isEmpty) return 0;
    return dua.arabic
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
  }

  addDuaToList(DuaModel duaModel) {
    int existingIndex = _allDuas.indexWhere((cat) => cat.id == duaModel.id);

    if (existingIndex == -1) {
      _allDuas.add(duaModel);
    } else {
      _allDuas[existingIndex] = duaModel;
    }
    // Sort by verse count (ascending), then by original order
    _allDuas.sort((a, b) {
      int countA = _getVerseCount(a);
      int countB = _getVerseCount(b);
      if (countA != countB) {
        return countA.compareTo(countB);
      }
      return a.order.compareTo(b.order);
    });
    update();
  }

  getAllDuas() {
    DuaService().getAllDuas();
  }

  getFilteredDuas(SubCategoryModel subCategoryModel) {
    _filteredDuas = _allDuas.where((dua) {
      return dua.subCategoryIds.contains(subCategoryModel.id);
    }).toList();

    // Also sort the filtered list just in case
    _filteredDuas.sort((a, b) {
      int countA = _getVerseCount(a);
      int countB = _getVerseCount(b);
      if (countA != countB) {
        return countA.compareTo(countB);
      }
      return a.order.compareTo(b.order);
    });
    update();
  }
}
