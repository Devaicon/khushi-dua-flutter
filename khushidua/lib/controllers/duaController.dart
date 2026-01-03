import 'package:get/get.dart';
import 'package:khushidua/models/subCategoryModel.dart';
import 'package:khushidua/services/duaService.dart';

import '../models/duaModel.dart';

class DuaController extends GetxController {
  final List<DuaModel> _allDuas = [];
  List<DuaModel> _filteredDuas = [];
  List<DuaModel> get allDuas => _allDuas;
  List<DuaModel> get filteredDuas => _filteredDuas;

  addDuaToList(DuaModel duaModel) {
    int existingIndex = _allDuas.indexWhere((cat) => cat.id == duaModel.id);

    if (existingIndex == -1) {
      _allDuas.add(duaModel);
    } else {
      _allDuas[existingIndex] = duaModel;
    }
    _allDuas.sort((a, b) => a.order.compareTo(b.order));
    update();
  }

  getAllDuas() {
    DuaService().getAllDuas();
  }

  getFilteredDuas(SubCategoryModel subCategoryModel) {
    _filteredDuas = _allDuas.where((dua) {
      return dua.subCategoryIds.contains(subCategoryModel.id);
    }).toList();
    update();
  }
}
