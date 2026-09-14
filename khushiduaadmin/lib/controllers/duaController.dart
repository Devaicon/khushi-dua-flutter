import 'dart:html';

import 'package:get/get.dart';
import 'package:khushiduaadmin/services/duaService.dart';

import '../models/duaModel.dart';

class DuaController extends GetxController {
  final List<DuaModel> _allDuas = [];
  List<DuaModel> get allDuas => _allDuas;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  setLoading(bool value) {
    _isLoading = value;
    update();
  }

  getAllDuas() {
    DuaService().getAllDuas();
  }

  addDuaToList(DuaModel duaModel, {bool shouldUpdate = true}) {
    int existingIndex = _allDuas.indexWhere((cat) => cat.id == duaModel.id);

    if (existingIndex == -1) {
      _allDuas.add(duaModel);
    } else {
      _allDuas[existingIndex] = duaModel;
    }
    _allDuas.sort((a, b) => a.order.compareTo(b.order));
    if (shouldUpdate) update();
  }

  removeDuaFromList(String id) {
    _allDuas.removeWhere((dua) => dua.id == id);
    update();
  }

  createDua(DuaModel duaModel, File? grownUpmp3File, File? littleKidmp3File,
      File? olderKidmp3File) {
    DuaService()
        .createDua(duaModel, grownUpmp3File, littleKidmp3File, olderKidmp3File);
  }

  updateDua(DuaModel duaModel, File? grownUpmp3File, File? littleKidmp3File,
      File? olderKidmp3File, File? englishTrans, File? urduTrans) {
    DuaService().updateDua(duaModel, grownUpmp3File, littleKidmp3File,
        olderKidmp3File, englishTrans, urduTrans);
  }

  deleteDua(DuaModel duaModel,
      {required bool deleteLittleKids,
      required bool deleteOlderKids,
      required bool deleteGrownUps}) {
    DuaService().deleteDua(duaModel,
        deleteLittleKids: deleteLittleKids,
        deleteOlderKids: deleteOlderKids,
        deleteGrownUps: deleteGrownUps);
  }
}
