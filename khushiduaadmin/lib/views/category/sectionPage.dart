import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../models/duaModel.dart';
import '../../services/duaService.dart';
import '../../widgets/audioBadges.dart';
import '../../widgets/audioPlayButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/reorderList.dart';
import '../../widgets/ui.dart';
import '../duas/duaEditor.dart';
import 'itemEditor.dart';

/// One section: its duas in the app's order, with what each is missing.
class SectionPage extends StatefulWidget {
  const SectionPage({super.key, required this.sectionId});
  final String sectionId;

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  /// Which age group's view of the section to show; null for every dua.
  AgeGroup? _group;

  Future<void> _reorder(List<DuaModel> next, String name) async {
    final saving = DuaService().reorder(next, sectionName: name);
    Get.find<DuaController>().markLoaded();
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
            final section = c.sectionById(widget.sectionId);
            if (section == null) {
              return const AdminPage(
                leading: BackButtonCircle(),
                title: 'Section not found',
                child: EmptyState(
                  icon: Icons.layers_clear_outlined,
                  title: 'This section was deleted',
                  message: 'Restore it from History if that was a mistake.',
                ),
              );
            }
            final all = duas.inSection(section.id);
            final shown = _group == null
                ? all
                : [for (final d in all) if (d.isEnabled && d.shownTo(_group!)) d];
            final missing =
                all.where((d) => d.missingRecitations.isNotEmpty).length;

            return AdminPage(
              leading: const BackButtonCircle(),
              title: section.title,
              subtitle:
                  '${c.categoryById(section.categoryId)?.title ?? 'No category'} · '
                  '${all.length} duas'
                  '${missing > 0 ? ' · $missing missing a recitation' : ''}',
              actions: [
                StatusChip(section.isEnabled ? 'Live' : 'Hidden',
                    tone: section.isEnabled ? Tone.success : Tone.neutral),
                AdminButton.secondary(
                  label: 'Edit section',
                  icon: Icons.edit_outlined,
                  onPressed: () =>
                      pushPage(context, ItemEditor.section(section: section)),
                ),
                AdminButton(
                  label: 'Add dua',
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      pushPage(context, DuaEditor(sectionId: section.id)),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('As seen by ', style: AdminText.muted),
                      const SizedBox(width: Space.sm),
                      SegmentedButton<AgeGroup?>(
                        segments: [
                          const ButtonSegment(value: null, label: Text('All duas')),
                          for (final g in AgeGroup.values)
                            ButtonSegment(value: g, label: Text(g.label)),
                        ],
                        selected: {_group},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _group = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  if (_group != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Text(
                        'Showing the ${shown.length} duas ${_group!.label} see, '
                        'in their order. Switch to All duas to reorder.',
                        style: AdminText.muted,
                      ),
                    ),
                  ReorderList<DuaModel>(
                    items: shown,
                    idOf: (d) => d.id,
                    reorderable: _group == null,
                    onReorder: (next) => _reorder(next, section.title),
                    onTap: (d) => pushPage(context, DuaEditor(dua: d)),
                    empty: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No duas here yet',
                      action: AdminButton(
                        label: 'Add dua',
                        icon: Icons.add_rounded,
                        onPressed: () =>
                            pushPage(context, DuaEditor(sectionId: section.id)),
                      ),
                    ),
                    rowBuilder: (d) => Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                d.arabic.replaceAll('\n', ' '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                style: AdminText.muted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.lg),
                        SizedBox(width: 236, child: AudioBadges(d)),
                        AgeDots(shownTo: d.shownTo),
                        const SizedBox(width: Space.md),
                        SizedBox(
                          width: 80,
                          child: StatusChip(d.isEnabled ? 'Live' : 'Hidden',
                              tone: d.isEnabled ? Tone.success : Tone.neutral),
                        ),
                        AudioPlayButton(
                          url: d.recitationFor(_group ?? AgeGroup.grownUps),
                          tooltip: 'Play ${(_group ?? AgeGroup.grownUps).label}',
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Palette.textMuted),
                      ],
                    ),
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
