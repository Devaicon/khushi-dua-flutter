import 'package:get/get.dart';

import '../models/mlSettingsModel.dart';
import '../services/mlSettingsService.dart';

/// The Practice button's settings, as last read.
class MLSettingsController extends GetxController {
  MLSettingsModel? _mlSettings;
  MLSettingsModel? get mlSettings => _mlSettings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    update();
  }

  void setMLSettings(MLSettingsModel? mlSettings) {
    _mlSettings = mlSettings;
    update();
  }

  Future<void> getMLSettings() => MLSettingsService().getMLSettings();

  Future<void> saveUrl(String url) => MLSettingsService().saveUrl(url);

  /// Publishes the Practice switch straight away; the app follows it live.
  Future<void> setPracticeEnabled(bool enabled) =>
      MLSettingsService().setPracticeEnabled(enabled);
}
