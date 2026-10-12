import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';
import '../controllers/categoryController.dart';
import '../search/adminSearch.dart';
import 'ui.dart';

/// Chooses the sections a dua appears in: the chosen ones as removable
/// chips, then every category's sections as a searchable checklist.
class SectionPicker extends StatefulWidget {
  const SectionPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<SectionPicker> createState() => _SectionPickerState();
}

class _SectionPickerState extends State<SectionPicker> {
  String _query = '';

  void _toggle(String id, bool on) {
    final next = [...widget.selected];
    on ? next.add(id) : next.remove(id);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (c) {
        final searching = hasSearchText(_query);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.selected.isNotEmpty) ...[
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final id in widget.selected)
                    InputChip(
                      label: Text(c.sectionPath(id)),
                      onDeleted: () => _toggle(id, false),
                      backgroundColor: Palette.brandSoft,
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: Space.md),
            ],
            TextField(
              decoration: const InputDecoration(
                hintText: 'Find a section or category',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: Space.sm),
            Container(
              height: 340,
              decoration: BoxDecoration(
                border: Border.all(color: Palette.line),
                borderRadius: Radii.smAll,
              ),
              child: ListView(
                children: [
                  for (final category in c.allCategories)
                    () {
                      final sections = c.sectionsOf(category.id).where((s) =>
                          !searching ||
                          matchesQuery(_query, [category.title, s.title]));
                      if (sections.isEmpty) return const SizedBox.shrink();
                      final chosen = sections
                          .where((s) => widget.selected.contains(s.id))
                          .length;
                      return ExpansionTile(
                        key: PageStorageKey('${category.id}-$searching'),
                        initiallyExpanded: searching || chosen > 0,
                        shape: const Border(),
                        title: Text(category.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${sections.length} sections'
                          '${chosen > 0 ? ' · $chosen chosen' : ''}'
                          '${category.isEnabled ? '' : ' · hidden category'}',
                          style: AdminText.muted,
                        ),
                        children: [
                          for (final s in sections)
                            CheckboxListTile(
                              dense: true,
                              value: widget.selected.contains(s.id),
                              onChanged: (v) => _toggle(s.id, v ?? false),
                              title: Text(s.title),
                              subtitle: s.isEnabled
                                  ? null
                                  : Text('Hidden section',
                                      style: AdminText.muted),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                        ],
                      );
                    }(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
