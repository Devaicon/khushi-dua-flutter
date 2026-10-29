import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../models/categoryModel.dart';
import '../../models/subCategoryModel.dart';
import '../../models/translatedItem.dart';
import '../../services/categoryService.dart';
import '../../services/duaService.dart';
import '../../services/storageService.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';
import '../../widgets/networkPicture.dart';

/// Creates or edits a category or a section (subcategory): its name in every
/// language, image, age groups and visibility.
///
/// One screen for both, replacing four near-identical 1,500-line forms that
/// required every one of the 21 names before saving.
class ItemEditor extends StatefulWidget {
  const ItemEditor.category({super.key, CategoryModel? category})
      : item = category,
        categoryId = null;

  const ItemEditor.section({super.key, SubCategoryModel? section, this.categoryId})
      : item = section;

  final TranslatedItem? item;

  /// For a new section, the category it goes in.
  final String? categoryId;

  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  late final TranslatedItem _draft;
  final Map<String, TextEditingController> _names = {};
  html.File? _image;
  String? _imagePreview;
  bool _dirty = false;
  bool _saving = false;
  bool _showErrors = false;

  bool get _isSection => widget.item is SubCategoryModel || widget.categoryId != null;
  bool get _isNew => widget.item == null;
  String get _noun => _isSection ? 'section' : 'category';

  @override
  void initState() {
    super.initState();
    final c = Get.find<CategoryController>();
    final existing = widget.item;
    if (existing is CategoryModel) {
      _draft = existing.copy();
    } else if (existing is SubCategoryModel) {
      _draft = existing.copy();
    } else if (_isSection) {
      final siblings = c.sectionsOf(widget.categoryId!);
      _draft = SubCategoryModel.empty(widget.categoryId!)
        ..order = siblings.isEmpty ? 0 : siblings.last.order + 1;
    } else {
      final all = c.allCategories;
      _draft = CategoryModel.empty()
        ..order = all.isEmpty ? 0 : all.last.order + 1;
    }
    for (final l in kContentLanguages) {
      _names[l.field] = TextEditingController(text: _draft.text(l.field))
        ..addListener(() {
          // Listeners also fire when the cursor moves; only a text change counts.
          final text = _names[l.field]!.text;
          if (text == _draft.text(l.field)) return;
          _draft.setText(l.field, text);
          _touch();
        });
    }
  }

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() => setState(() => _dirty = true);

  Future<void> _pickImage() async {
    final files = await pickFiles(accept: 'image/*,.svg');
    if (files.isEmpty) return;
    setState(() {
      _image = files.first;
      _imagePreview = html.Url.createObjectUrlFromBlob(files.first);
    });
    _touch();
  }

  Future<void> _save() async {
    if (_draft.english.trim().isEmpty) {
      setState(() => _showErrors = true);
      CustomSnackbar.show("Can't save yet", 'Add the English name.', isSuccess: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await CategoryService().save(_draft, image: _image);
      _dirty = false;
      CustomSnackbar.show(
        _isNew ? '${_capital(_noun)} created' : '${_capital(_noun)} saved',
        'Phones will pick it up the next time the app opens.',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      CustomSnackbar.show("Couldn't save", '$e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Only an empty category or section can be deleted; anything else would
  /// leave sections or duas pointing at nothing.
  String? get _deleteBlocker {
    if (_isNew) return null;
    if (_isSection) {
      final duas = Get.find<DuaController>().inSection(_draft.id);
      final onlyHere = duas.where((d) => d.subCategoryIds.length == 1).length;
      if (onlyHere > 0) {
        return 'Move or delete its $onlyHere duas that are in no other section first.';
      }
      return null;
    }
    final sections = Get.find<CategoryController>().sectionsOf(_draft.id);
    if (sections.isNotEmpty) {
      return 'Move or delete its ${sections.length} sections first.';
    }
    return null;
  }

  Future<void> _delete() async {
    final blocker = _deleteBlocker;
    if (blocker != null) {
      CustomSnackbar.show("Can't delete this $_noun", blocker, isSuccess: false);
      return;
    }
    if (!await confirmAction(
      context,
      title: 'Delete this $_noun?',
      message: '"${_draft.title}" will disappear from the app. You can '
          'restore it from History.',
      confirmLabel: 'Delete $_noun',
      danger: true,
    )) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isSection) {
        // Take it off any duas that are also in other sections.
        final duas = Get.find<DuaController>().inSection(_draft.id);
        for (final dua in duas) {
          await DuaService().removeFromSection(dua, _draft.id);
        }
      }
      await CategoryService().delete(_draft);
      _dirty = false;
      CustomSnackbar.show('${_capital(_noun)} deleted', 'Restore it from History if needed.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      CustomSnackbar.show("Couldn't delete", '$e', isSuccess: false);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _popAfterConfirm() async {
    final navigator = Navigator.of(context);
    if (!await confirmAction(
      context,
      title: 'Discard your changes?',
      message: 'You have changes to this $_noun that are not saved.',
      confirmLabel: 'Discard',
      danger: true,
    )) {
      return;
    }
    _dirty = false;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CategoryController>();
    final draft = _draft;
    final section = draft is SubCategoryModel ? draft : null;
    final filled = kContentLanguages.where((l) => _draft.text(l.field).trim().isNotEmpty).length;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popAfterConfirm();
      },
      child: Scaffold(
        body: Stack(
          children: [
            AdminPage(
              leading: const BackButtonCircle(),
              title: _isNew ? 'New $_noun' : 'Edit $_noun',
              subtitle: _isNew
                  ? (section != null
                      ? 'In ${c.categoryById(section.categoryId)?.title ?? 'a category'}'
                      : 'Shown as a tile on the app\'s home screen')
                  : _draft.title,
              actions: [
                if (!_isNew)
                  AdminButton.secondary(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    onPressed: _saving ? null : _delete,
                    tooltip: _deleteBlocker,
                  ),
                AdminButton(
                  label: _isNew ? 'Create $_noun' : 'Save changes',
                  icon: Icons.check_rounded,
                  busy: _saving,
                  onPressed: _isNew || _dirty ? _save : null,
                ),
              ],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AdminCard(
                      title: 'Names',
                      subtitle: '$filled of ${kContentLanguages.length} languages. '
                          'Empty ones fall back to English in the app.',
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final columns = box.maxWidth > 640 ? 2 : 1;
                          final width = (box.maxWidth - Space.lg * (columns - 1)) / columns;
                          return Wrap(
                            spacing: Space.lg,
                            runSpacing: Space.lg,
                            children: [
                              for (final l in kContentLanguages)
                                SizedBox(
                                  width: width,
                                  child: TextField(
                                    controller: _names[l.field],
                                    textDirection: l.rtl ? TextDirection.rtl : TextDirection.ltr,
                                    decoration: InputDecoration(
                                      labelText: l.field == 'english' ? 'English (required)' : l.label,
                                      errorText: _showErrors &&
                                              l.field == 'english' &&
                                              _draft.english.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.xl),
                  SizedBox(
                    width: 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminCard(
                          title: _isSection ? 'Illustration' : 'Logo',
                          subtitle: _isSection
                              ? 'Shown above the duas for kids. Optional.'
                              : 'The icon on the home screen tile.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Palette.raised,
                                  borderRadius: Radii.smAll,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _imagePreview != null
                                    ? NetworkPicture(_imagePreview!,
                                        svg: isSvgFile(_image!))
                                    : (_draft.imageUrl.isEmpty
                                        ? Icon(Icons.image_outlined,
                                            color: Palette.textMuted, size: 48)
                                        : NetworkPicture(_draft.imageUrl)),
                              ),
                              const SizedBox(height: Space.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: AdminButton.secondary(
                                      label: _draft.imageUrl.isEmpty && _image == null
                                          ? 'Upload image'
                                          : 'Replace image',
                                      icon: Icons.upload_rounded,
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                  if (_isSection && (_draft.imageUrl.isNotEmpty || _image != null))
                                    IconButton(
                                      tooltip: 'Remove the illustration',
                                      onPressed: () {
                                        setState(() {
                                          _image = null;
                                          _imagePreview = null;
                                          _draft.imageUrl = '';
                                        });
                                        _touch();
                                      },
                                      icon: Icon(Icons.close_rounded, color: Palette.danger),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        AdminCard(
                          title: 'Visibility',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _draft.isEnabled,
                                title: const Text('Shown in the app'),
                                onChanged: (v) {
                                  setState(() => _draft.isEnabled = v);
                                  _touch();
                                },
                              ),
                              const SizedBox(height: Space.sm),
                              const FieldLabel('Age groups'),
                              Wrap(
                                spacing: Space.sm,
                                runSpacing: Space.sm,
                                children: [
                                  for (final g in AgeGroup.values)
                                    FilterChip(
                                      label: Text(g.label),
                                      selected: _draft.shownTo(g),
                                      selectedColor: AgeDots.colorOf(g).withValues(alpha: 0.35),
                                      checkmarkColor: inkOf(AgeDots.colorOf(g)),
                                      onSelected: (v) {
                                        setState(() => _draft.setShownTo(g, v));
                                        _touch();
                                      },
                                    ),
                                ],
                              ),
                              if (section != null) ...[
                                const SizedBox(height: Space.lg),
                                const FieldLabel('Category'),
                                DropdownButtonFormField<String>(
                                  initialValue: c.categoryById(section.categoryId) == null
                                      ? null
                                      : section.categoryId,
                                  items: [
                                    for (final cat in c.allCategories)
                                      DropdownMenuItem(value: cat.id, child: Text(cat.title)),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => section.categoryId = v);
                                    _touch();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_isNew) ...[
                          const SizedBox(height: Space.md),
                          SelectableText('Id: ${_draft.id}', style: AdminText.mono),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_saving) const BusyOverlay(),
          ],
        ),
      ),
    );
  }
}

String _capital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
