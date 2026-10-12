import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../models/subCategoryModel.dart';
import '../../services/categoryService.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/reorderList.dart';
import '../../widgets/ui.dart';
import 'itemEditor.dart';
import 'sectionPage.dart';

/// One category: its details, and its sections in the app's order.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.categoryId});
  final String categoryId;

  Future<void> _reorder(List<SubCategoryModel> next, String name) async {
    final saving = CategoryService().reorder(next, label: 'sections in $name');
    Get.find<CategoryController>().resort();
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
            final category = c.categoryById(categoryId);
            if (category == null) {
              return const AdminPage(
                leading: BackButtonCircle(),
                title: 'Category not found',
                child: EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'This category was deleted',
                  message: 'Restore it from History if that was a mistake.',
                ),
              );
            }
            final sections = c.sectionsOf(categoryId);
            return AdminPage(
              leading: const BackButtonCircle(),
              title: category.title,
              subtitle: '${sections.length} sections · drag to change their '
                  'order in the app',
              actions: [
                StatusChip(category.isEnabled ? 'Live' : 'Hidden',
                    tone: category.isEnabled ? Tone.success : Tone.neutral),
                AdminButton.secondary(
                  label: 'Edit category',
                  icon: Icons.edit_outlined,
                  onPressed: () => pushPage(
                      context, ItemEditor.category(category: category)),
                ),
                AdminButton(
                  label: 'New section',
                  icon: Icons.add_rounded,
                  onPressed: () => pushPage(
                      context, ItemEditor.section(categoryId: categoryId)),
                ),
              ],
              child: ReorderList<SubCategoryModel>(
                items: sections,
                idOf: (s) => s.id,
                onReorder: (next) => _reorder(next, category.title),
                onTap: (s) => pushPage(context, SectionPage(sectionId: s.id)),
                empty: EmptyState(
                  icon: Icons.layers_outlined,
                  title: 'No sections yet',
                  message: 'A category needs sections to hold its duas.',
                  action: AdminButton(
                    label: 'New section',
                    icon: Icons.add_rounded,
                    onPressed: () => pushPage(
                        context, ItemEditor.section(categoryId: categoryId)),
                  ),
                ),
                rowBuilder: (s) {
                  final inSection = duas.inSection(s.id);
                  final missing =
                      inSection.where((d) => d.missingRecitations.isNotEmpty).length;
                  return Row(
                    children: [
                      ItemThumb(s.image),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('${inSection.length} duas', style: AdminText.muted),
                          ],
                        ),
                      ),
                      if (missing > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: Space.md),
                          child: StatusChip('$missing missing a recitation',
                              tone: Tone.warning, icon: Icons.graphic_eq_rounded),
                        ),
                      AgeDots(shownTo: s.shownTo),
                      const SizedBox(width: Space.lg),
                      SizedBox(
                        width: 80,
                        child: StatusChip(s.isEnabled ? 'Live' : 'Hidden',
                            tone: s.isEnabled ? Tone.success : Tone.neutral),
                      ),
                      IconButton(
                        tooltip: 'Edit section',
                        onPressed: () =>
                            pushPage(context, ItemEditor.section(section: s)),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Palette.textMuted),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
