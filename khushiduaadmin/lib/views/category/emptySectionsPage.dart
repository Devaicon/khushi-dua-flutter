import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../models/subCategoryModel.dart';
import '../../widgets/reorderList.dart';
import '../../widgets/ui.dart';
import 'itemEditor.dart';
import 'sectionPage.dart';

/// The live sections that hold no duas, which readers see empty in the app.
/// Opened from the overview's "Needs attention".
class EmptySectionsPage extends StatelessWidget {
  const EmptySectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<DuaController>(
        builder: (duas) => GetBuilder<CategoryController>(
          builder: (c) {
            final empty = [
              for (final s in c.allSubCategories)
                if (s.isEnabled && duas.inSection(s.id).isEmpty) s,
            ];
            return AdminPage(
              leading: const BackButtonCircle(),
              title: 'Empty sections',
              subtitle: empty.isEmpty
                  ? 'Every live section has duas.'
                  : '${empty.length} live sections have no duas, so they show '
                      'up empty in the app. Add duas to them or hide them.',
              child: ReorderList<SubCategoryModel>(
                items: empty,
                idOf: (s) => s.id,
                reorderable: false,
                onReorder: (_) {},
                onTap: (s) => pushPage(context, SectionPage(sectionId: s.id)),
                empty: const EmptyState(
                  icon: Icons.verified_rounded,
                  title: 'Nothing to fix',
                  message: 'Every live section has at least one dua.',
                ),
                rowBuilder: (s) => Row(
                  children: [
                    ItemThumb(s.image),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(
                            'In ${c.categoryById(s.categoryId)?.title ?? 'no category'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminText.muted,
                          ),
                        ],
                      ),
                    ),
                    const StatusChip('No duas',
                        tone: Tone.warning, icon: Icons.layers_outlined),
                    const SizedBox(width: Space.lg),
                    AgeDots(shownTo: s.shownTo),
                    IconButton(
                      tooltip: 'Edit section',
                      onPressed: () =>
                          pushPage(context, ItemEditor.section(section: s)),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Palette.textMuted),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
