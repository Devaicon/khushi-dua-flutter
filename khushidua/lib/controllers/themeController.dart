import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _kAgeGroup = 'selectedAgeGroup';

  /// The age group chosen last session. Read in main() before the first frame
  /// so the home screen opens on it instead of flashing Little Kids first.
  static int _savedAgeGroup = 0;

  static Future<void> loadSavedAgeGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedAgeGroup = (prefs.getInt(_kAgeGroup) ?? 0).clamp(0, 2);
    } catch (_) {
      // A broken preferences store must not stop the app from launching.
    }
  }

  int _selectedAgeGroup = _savedAgeGroup;

  int get selectedAgeGroup => _selectedAgeGroup;

  double _textSize = 20;
  double get textSize => _textSize;

  bool _showTranslation = true;
  bool get showTranslation => _showTranslation;

  bool _showTransliteration = false;
  bool get showTransliteration => _showTransliteration;

  setShowTransliteration(bool value) {
    _showTransliteration = value;
    update();
  }

  setShowTranslation(bool value) {
    _showTranslation = value;
    update();
  }

  setTextSize(double value) {
    _textSize = value;
    update();
  }

  setSelectedAgeGroup(int value) {
    _selectedAgeGroup = value;
    SharedPreferences.getInstance().then((p) => p.setInt(_kAgeGroup, value));
    try {
      Get.find<CategoryController>().refreshAll();
      Get.find<DuaController>().refreshFilteredDuas();
    } catch (e) {
      // Ignored if controllers not yet registered during first setup
    }
    update();
  }
}
