import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../models/categoryModel.dart';
import '../../search/adminSearch.dart';
import '../../services/categoryService.dart';
import '../../widgets/adminSearchField.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/reorderList.dart';
import '../../widgets/ui.dart';
import '../category/categoryPage.dart';
import '../category/itemEditor.dart';

/// The home screen's categories, in the app's order. Drag to reorder; open
/// one for its sections.
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  String _query = '';

  Future<void> _reorder(List<CategoryModel> next) async {
    final controller = Get.find<CategoryController>();
    final saving = CategoryService().reorder(next, label: 'categories');
    controller.resort();
    try {
      await saving;
    } catch (e) {
      CustomSnackbar.show("Couldn't save the new order", '$e', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<DuaController>(
        builder: (duas) => GetBuilder<CategoryController>(
          builder: (c) {
            final searching = hasSearchText(_query);
            final visible =
                filterBySearch(c.allCategories, _query, categorySearchFields);
            return AdminPage(
              title: 'Categories',
              subtitle: '${c.allCategories.length} categories · '
                  '${c.allSubCategories.length} sections. Drag to change the '
                  'order on the app\'s home screen.',
              actions: [
                AdminButton(
                  label: 'New category',
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      pushPage(context, const ItemEditor.category()),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSearchField(
                    hint: 'Search categories by any language or id',
                    matchCount: visible.length,
                    totalCount: c.allCategories.length,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (searching)
                    SearchResultsNote(
                      query: _query,
                      matchCount: visible.length,
                      itemLabel: 'categories',
                      reorderPaused: true,
                    ),
                  const SizedBox(height: Space.lg),
                  ReorderList<CategoryModel>(
                    items: visible,
                    idOf: (cat) => cat.id,
                    reorderable: !searching,
                    onReorder: _reorder,
                    onTap: (cat) =>
                        pushPage(context, CategoryPage(categoryId: cat.id)),
                    empty: EmptyState(
                      icon: Icons.folder_off_outlined,
                      title: c.loaded ? 'No categories match' : 'Loading…',
                    ),
                    rowBuilder: (cat) {
                      final sections = c.sectionsOf(cat.id);
                      final duaCount = {
                        for (final s in sections)
                          for (final d in duas.inSection(s.id)) d.id,
                      }.length;
                      return Row(
                        children: [
                          ItemThumb(cat.logo),
                          const SizedBox(width: Space.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                Text(
                                  '${sections.length} sections · $duaCount duas'
                                  '${cat.urdu.isEmpty ? '' : ' · ${cat.urdu}'}',
                                  style: AdminText.muted,
                                ),
                              ],
                            ),
                          ),
                          AgeDots(shownTo: cat.shownTo),
                          const SizedBox(width: Space.lg),
                          SizedBox(
                            width: 80,
                            child: StatusChip(
                              cat.isEnabled ? 'Live' : 'Hidden',
                              tone: cat.isEnabled ? Tone.success : Tone.neutral,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit category',
                            onPressed: () => pushPage(
                                context, ItemEditor.category(category: cat)),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Palette.textMuted),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
