import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/homeBannerController.dart';
import '../../models/homeBannerModel.dart';
import '../../widgets/customLoading.dart';
import '../../widgets/topBar.dart';

/// Edits the banner shown at the top of the app's home screen.
///
/// English is required; the other languages are optional and collapsed by
/// default, because a banner with only English still displays correctly for
/// every user.
class HomeBannerTab extends StatefulWidget {
  const HomeBannerTab({super.key});

  @override
  State<HomeBannerTab> createState() => _HomeBannerTabState();
}

class _HomeBannerTabState extends State<HomeBannerTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _subtitleControllers = {};

  bool _isEnabled = false;
  bool _showTranslations = false;
  String _linkCategoryId = '';
  String _existingImageUrl = '';

  html.File? _pickedImage;
  String? _pickedImagePreviewUrl;

  /// Guards against re-seeding the fields every time the controller notifies.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    for (final language in HomeBannerModel.languages) {
      _titleControllers[language] = TextEditingController();
      _subtitleControllers[language] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<HomeBannerController>().getBanner();
    });
  }

  @override
  void dispose() {
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _subtitleControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(HomeBannerModel banner) {
    if (_seeded) return;
    _seeded = true;

    for (final language in HomeBannerModel.languages) {
      _titleControllers[language]!.text = banner.title[language] ?? '';
      _subtitleControllers[language]!.text = banner.subtitle[language] ?? '';
    }
    _isEnabled = banner.isEnabled;
    _linkCategoryId = banner.linkCategoryId;
    _existingImageUrl = banner.imageUrl;
  }

  void _pickImage() {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((_) {
      if (input.files == null || input.files!.isEmpty) return;
      final file = input.files!.first;
      setState(() {
        _pickedImage = file;
        _pickedImagePreviewUrl = html.Url.createObjectUrl(file);
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final banner = HomeBannerModel(
      isEnabled: _isEnabled,
      title: {
        for (final l in HomeBannerModel.languages)
          l: _titleControllers[l]!.text.trim(),
      },
      subtitle: {
        for (final l in HomeBannerModel.languages)
          l: _subtitleControllers[l]!.text.trim(),
      },
      imageUrl: _existingImageUrl,
      linkCategoryId: _linkCategoryId,
      updatedAt: DateTime.now(),
    );

    final saved = await Get.find<HomeBannerController>().saveBanner(
      banner,
      imageFile: _pickedImage,
    );

    if (saved && mounted) {
      setState(() {
        _existingImageUrl = banner.imageUrl;
        _pickedImage = null;
        _pickedImagePreviewUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rBlack,
      body: GetBuilder<HomeBannerController>(
        builder: (controller) {
          if (controller.loaded) _seedFrom(controller.banner);

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TopBar(title: "Home Banner"),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            _section(
                              title: "Visibility",
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeColor: rGreen,
                                value: _isEnabled,
                                title: const Text(
                                  "Show this banner in the app",
                                  style: TextStyle(color: rWhite),
                                ),
                                subtitle: const Text(
                                  "When off, the app falls back to its built-in banner text.",
                                  style: TextStyle(color: rHint, fontSize: 12),
                                ),
                                onChanged: (v) =>
                                    setState(() => _isEnabled = v),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _section(
                              title: "English (required)",
                              child: Column(
                                children: [
                                  _field(
                                    controller:
                                        _titleControllers[
                                          HomeBannerModel.fallbackLanguage
                                        ]!,
                                    label: "Title",
                                    hint: "Ready to learn and play?",
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? "An English title is required"
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    controller:
                                        _subtitleControllers[
                                          HomeBannerModel.fallbackLanguage
                                        ]!,
                                    label: "Subtitle",
                                    hint:
                                        "Listen to available duas to UNLOCK remaining duas",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _translationsSection(),
                            const SizedBox(height: 16),
                            _imageSection(),
                            const SizedBox(height: 16),
                            _linkSection(),
                            const SizedBox(height: 24),
                            _saveButton(controller),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.loading) const CustomLoading(),
            ],
          );
        },
      ),
    );
  }

  Widget _translationsSection() {
    final otherLanguages = HomeBannerModel.languages
        .where((l) => l != HomeBannerModel.fallbackLanguage)
        .toList();

    final filled = otherLanguages
        .where((l) => _titleControllers[l]!.text.trim().isNotEmpty)
        .length;

    return _section(
      title: "Other languages",
      trailing: Text(
        "$filled of ${otherLanguages.length} filled",
        style: const TextStyle(color: rHint, fontSize: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Optional. Any language left blank shows the English text instead.",
            style: TextStyle(color: rHint, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                setState(() => _showTranslations = !_showTranslations),
            icon: Icon(
              _showTranslations
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: rGreen,
            ),
            label: Text(
              _showTranslations ? "Hide translations" : "Show translations",
              style: const TextStyle(color: rGreen),
            ),
          ),
          if (_showTranslations)
            for (final language in otherLanguages) ...[
              const SizedBox(height: 12),
              Text(
                language,
                style: const TextStyle(
                  color: rWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _field(
                controller: _titleControllers[language]!,
                label: "Title",
                hint: "Leave blank to use English",
              ),
              const SizedBox(height: 8),
              _field(
                controller: _subtitleControllers[language]!,
                label: "Subtitle",
                hint: "Leave blank to use English",
              ),
              const Divider(color: rHint),
            ],
        ],
      ),
    );
  }

  Widget _imageSection() {
    final preview = _pickedImagePreviewUrl ?? _existingImageUrl;

    return _section(
      title: "Image",
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: rBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rHint.withOpacity(0.4)),
            ),
            child: preview.isEmpty
                ? const Icon(Icons.image_outlined, color: rHint)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      preview,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, color: rHint),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Leave empty to keep the image built into the app.",
                  style: TextStyle(color: rHint, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_rounded, color: rGreen),
                      label: const Text(
                        "Choose image",
                        style: TextStyle(color: rGreen),
                      ),
                    ),
                    if (preview.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _pickedImage = null;
                          _pickedImagePreviewUrl = null;
                          _existingImageUrl = '';
                        }),
                        icon: const Icon(Icons.delete_outline, color: rRed),
                        label: const Text(
                          "Remove",
                          style: TextStyle(color: rRed),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkSection() {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        final categories = categoryController.allCategories;

        // The saved id may point at a category that has since been deleted;
        // fall back to "no link" rather than crashing the dropdown.
        final value = categories.any((c) => c.id == _linkCategoryId)
            ? _linkCategoryId
            : '';

        return _section(
          title: "Tap action",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose the category the banner opens when tapped.",
                style: TextStyle(color: rHint, fontSize: 12),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: value,
                dropdownColor: rBg,
                decoration: _inputDecoration("Opens", null),
                style: const TextStyle(color: rWhite),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text(
                      "Nothing — banner is not tappable",
                      style: TextStyle(color: rWhite),
                    ),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.english.isNotEmpty ? c.english : c.id,
                        style: const TextStyle(color: rWhite),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _linkCategoryId = v ?? ''),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _saveButton(HomeBannerController controller) {
    return Center(
      child: GestureDetector(
        onTap: controller.loading ? null : _save,
        child: Container(
          width: 220,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: rGreen),
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [rGreen.withOpacity(0.22), rGreen.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            "Save & publish",
            style: TextStyle(
              color: rWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: rWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: rWhite),
      validator: validator,
      decoration: _inputDecoration(label, hint),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: rHint),
      hintText: hint,
      hintStyle: const TextStyle(color: rHint, fontSize: 12),
      filled: true,
      fillColor: rBlack,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: rHint.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: rGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: rRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: rRed),
      ),
    );
  }
}
