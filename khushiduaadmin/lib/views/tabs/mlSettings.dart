import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/colors.dart';
import '../../controllers/mlSettingsController.dart';
import '../../widgets/topBar.dart';
import '../../widgets/customLoading.dart';

class MLSettingsTab extends StatefulWidget {
  const MLSettingsTab({super.key});

  @override
  State<MLSettingsTab> createState() => _MLSettingsTabState();
}

class _MLSettingsTabState extends State<MLSettingsTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _baseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load ML Settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MLSettingsController>().getMLSettings();
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  void _saveOrUpdate() {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<MLSettingsController>();
      if (controller.mlSettings == null) {
        // Create new
        controller.createMLSettings(_baseUrlController.text.trim());
      } else {
        // Update existing
        controller.updateMLSettings(_baseUrlController.text.trim());
      }
    }
  }

  void _delete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: rBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              "Delete ML Settings?",
              style: TextStyle(fontWeight: FontWeight.bold, color: rWhite),
            ),
          ),
          content: Text(
            "Are you sure you want to delete the ML Settings? This action cannot be undone.",
            style: TextStyle(fontSize: 16, color: rWhite),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: rGreen),
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          rGreen.withOpacity(0.22),
                          rGreen.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: rWhite, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Get.find<MLSettingsController>().deleteMLSettings();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: rRed),
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [rRed, rRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Delete",
                      style: TextStyle(color: rWhite, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<MLSettingsController>(
        builder: (mlSettingsController) {
          // Update text field when settings are loaded
          if (mlSettingsController.mlSettings != null && _baseUrlController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _baseUrlController.text = mlSettingsController.mlSettings!.baseUrl;
            });
          } else if (mlSettingsController.mlSettings == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _baseUrlController.clear();
            });
          }

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopBar(title: "ML Settings"),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: rBg,
                          ),
                          padding: EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ML Base URL Configuration",
                                      style: TextStyle(
                                        color: rWhite,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (mlSettingsController.mlSettings != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: rGreen.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: rGreen),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, color: rGreen, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              "Saved",
                                              style: TextStyle(
                                                color: rGreen,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "Base URL",
                                  style: TextStyle(
                                    color: rHint,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _baseUrlController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Base URL is required";
                                    }
                                    final uri = Uri.tryParse(value);
                                    if (uri == null || !uri.hasScheme) {
                                      return "Please enter a valid URL (e.g., https://example.com)";
                                    }
                                    return null;
                                  },
                                  cursorColor: rGreen,
                                  style: TextStyle(color: rWhite),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: rBlack,
                                    hintText: 'Enter ML Base URL (e.g., https://api.example.com)',
                                    hintStyle: TextStyle(color: rHint),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: rHint),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: rHint),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: rGreen),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: rRed),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: rRed),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                SizedBox(height: 24),
                                if (mlSettingsController.mlSettings != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: rBlack,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: rHint.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Settings Information:",
                                          style: TextStyle(
                                            color: rGreen,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        _buildInfoRow("ID", mlSettingsController.mlSettings!.id),
                                        _buildInfoRow(
                                          "Created At",
                                          "${mlSettingsController.mlSettings!.createdAt.day}/${mlSettingsController.mlSettings!.createdAt.month}/${mlSettingsController.mlSettings!.createdAt.year} ${mlSettingsController.mlSettings!.createdAt.hour}:${mlSettingsController.mlSettings!.createdAt.minute}",
                                        ),
                                        _buildInfoRow(
                                          "Last Updated",
                                          "${mlSettingsController.mlSettings!.updatedAt.day}/${mlSettingsController.mlSettings!.updatedAt.month}/${mlSettingsController.mlSettings!.updatedAt.year} ${mlSettingsController.mlSettings!.updatedAt.hour}:${mlSettingsController.mlSettings!.updatedAt.minute}",
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _saveOrUpdate,
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: rGreen,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            mlSettingsController.mlSettings == null ? "Save" : "Update",
                                            style: TextStyle(
                                              color: rWhite,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (mlSettingsController.mlSettings != null) ...[
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: InkWell(
                                          onTap: _delete,
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: rRed,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: rWhite,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (mlSettingsController.isLoading)
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: rBlack.withOpacity(0.7),
                  child: CustomLoading(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                color: rHint,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: rWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

