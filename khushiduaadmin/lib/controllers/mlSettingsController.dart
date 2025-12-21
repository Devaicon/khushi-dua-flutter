import 'package:get/get.dart';
import '../models/mlSettingsModel.dart';
import '../services/mlSettingsService.dart';

class MLSettingsController extends GetxController {
  MLSettingsModel? _mlSettings;
  MLSettingsModel? get mlSettings => _mlSettings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  setLoading(bool value) {
    _isLoading = value;
    update();
  }

  setMLSettings(MLSettingsModel? mlSettings) {
    _mlSettings = mlSettings;
    update();
  }

  getMLSettings() async {
    await MLSettingsService().getMLSettings();
  }

  createMLSettings(String baseUrl) async {
    await MLSettingsService().createMLSettings(baseUrl);
  }

  updateMLSettings(String baseUrl) async {
    if (_mlSettings != null) {
      await MLSettingsService().updateMLSettings(_mlSettings!, baseUrl);
    }
  }

  deleteMLSettings() async {
    if (_mlSettings != null) {
      await MLSettingsService().deleteMLSettings(_mlSettings!.id);
    }
  }
}

