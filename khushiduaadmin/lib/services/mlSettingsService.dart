import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebaseRef.dart';
import '../controllers/mlSettingsController.dart';
import '../models/mlSettingsModel.dart';
import '../widgets/customSnackbar.dart';

class MLSettingsService {
  final MLSettingsController _mlSettingsController =
      Get.find<MLSettingsController>();

  Future<void> getMLSettings() async {
    try {
      _mlSettingsController.setLoading(true);
      // Use SystemConfiguration/MemoizationURL
      final docSnapshot = await sysConfigRef.doc('MemoizationURL').get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final mlSettings = MLSettingsModel.fromMap({
          ...data,
          "id": docSnapshot.id,
        });
        _mlSettingsController.setMLSettings(mlSettings);
      } else {
        _mlSettingsController.setMLSettings(null);
      }
      _mlSettingsController.setLoading(false);
    } catch (e) {
      debugPrint("Error getting ML Settings: $e");
      _mlSettingsController.setLoading(false);
      CustomSnackbar.show("Error", "Failed to load ML Settings",
          isSuccess: false);
    }
  }

  Future<void> createMLSettings(String baseUrl) async {
    try {
      _mlSettingsController.setLoading(true);
      // Use SystemConfiguration/MemoizationURL with existing "URL" field
      final mlSettings = MLSettingsModel(
        id: "MemoizationURL",
        baseUrl: baseUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to SystemConfiguration/MemoizationURL - only update URL field
      await sysConfigRef.doc('MemoizationURL').set(
          {
            "URL": baseUrl,
            "updatedAt": DateTime.now(),
          },
          SetOptions(
              merge: true)); // merge: true se existing data preserve rahega

      _mlSettingsController.setMLSettings(mlSettings);
      _mlSettingsController.setLoading(false);

      debugPrint("=========================================");
      debugPrint("ML SETTINGS CREATED SUCCESSFULLY");
      debugPrint("=========================================");
      debugPrint("Firebase Path: /SystemConfiguration/MemoizationURL");
      debugPrint("Field: URL");
      debugPrint("Value: ${mlSettings.baseUrl}");
      debugPrint("=========================================");

      CustomSnackbar.show("Success",
          "ML Settings saved successfully!\nPath: /SystemConfiguration/MemoizationURL");
    } catch (e) {
      debugPrint("Error creating ML Settings: $e");
      _mlSettingsController.setLoading(false);
      CustomSnackbar.show("Error", "Failed to save ML Settings",
          isSuccess: false);
    }
  }

  Future<void> updateMLSettings(
      MLSettingsModel mlSettings, String baseUrl) async {
    try {
      _mlSettingsController.setLoading(true);
      mlSettings.baseUrl = baseUrl;
      mlSettings.updatedAt = DateTime.now();

      // Update SystemConfiguration/MemoizationURL - only update URL field
      await sysConfigRef.doc('MemoizationURL').update({
        "URL": baseUrl,
        "updatedAt": DateTime.now(),
      });

      _mlSettingsController.setMLSettings(mlSettings);
      _mlSettingsController.setLoading(false);

      debugPrint("=========================================");
      debugPrint("ML SETTINGS UPDATED SUCCESSFULLY");
      debugPrint("=========================================");
      debugPrint("Firebase Path: /SystemConfiguration/MemoizationURL");
      debugPrint("Field: URL");
      debugPrint("Value: ${mlSettings.baseUrl}");
      debugPrint("Updated At: ${mlSettings.updatedAt}");
      debugPrint("=========================================");

      CustomSnackbar.show("Success",
          "ML Settings updated successfully!\nPath: /SystemConfiguration/MemoizationURL");
    } catch (e) {
      debugPrint("Error updating ML Settings: $e");
      _mlSettingsController.setLoading(false);
      CustomSnackbar.show("Error", "Failed to update ML Settings",
          isSuccess: false);
    }
  }

  Future<void> deleteMLSettings(String id) async {
    try {
      _mlSettingsController.setLoading(true);
      // Delete from SystemConfiguration/MemoizationURL
      await sysConfigRef.doc('MemoizationURL').delete();
      _mlSettingsController.setMLSettings(null);
      _mlSettingsController.setLoading(false);

      debugPrint("=========================================");
      debugPrint("ML SETTINGS DELETED SUCCESSFULLY");
      debugPrint("=========================================");
      debugPrint("Deleted Path: /SystemConfiguration/MemoizationURL");
      debugPrint("=========================================");

      CustomSnackbar.show("Success", "ML Settings deleted successfully");
    } catch (e) {
      debugPrint("Error deleting ML Settings: $e");
      _mlSettingsController.setLoading(false);
      CustomSnackbar.show("Error", "Failed to delete ML Settings",
          isSuccess: false);
    }
  }
}
