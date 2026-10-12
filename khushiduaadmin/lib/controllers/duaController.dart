import 'package:get/get.dart';

import '../models/duaModel.dart';
import '../services/duaService.dart';

class DuaController extends GetxController {
  final List<DuaModel> _allDuas = [];
  List<DuaModel> get allDuas => _allDuas;

  bool _loaded = false;
  bool get loaded => _loaded;

  void getAllDuas() => DuaService().listen();

  DuaModel? byId(String id) => _allDuas.firstWhereOrNull((d) => d.id == id);

  /// The duas in a section, in the order the app shows them.
  List<DuaModel> inSection(String sectionId) =>
      [for (final d in _allDuas) if (d.subCategoryIds.contains(sectionId)) d];

  void addDuaToList(DuaModel duaModel, {bool shouldUpdate = true}) {
    final existingIndex = _allDuas.indexWhere((d) => d.id == duaModel.id);
    if (existingIndex == -1) {
      _allDuas.add(duaModel);
    } else {
      _allDuas[existingIndex] = duaModel;
    }
    if (shouldUpdate) _sortAndUpdate();
  }

  void removeDuaFromList(String id, {bool shouldUpdate = true}) {
    _allDuas.removeWhere((dua) => dua.id == id);
    if (shouldUpdate) _sortAndUpdate();
  }

  void markLoaded() {
    _loaded = true;
    _sortAndUpdate();
  }

  /// By position, then id, so equal positions keep a stable order.
  void _sortAndUpdate() {
    _allDuas.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
    update();
  }
}
