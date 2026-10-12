import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../models/audioSlot.dart';
import '../../models/duaModel.dart';
import '../../search/adminSearch.dart';
import '../../widgets/adminSearchField.dart';
import '../../widgets/audioBadges.dart';
import '../../widgets/audioPlayButton.dart';
import '../../widgets/ui.dart';
import '../duas/duaEditor.dart';

/// Which duas the list shows, beyond the search.
class DuaFilter {
  String? categoryId;
  String? sectionId;
  AgeGroup? ageGroup;

  /// null: any; true: live only; false: hidden only.
  bool? live;

  /// Show only duas missing this recording; [anyAudio] for any.
  AudioSlot? missing;
  bool anyAudio = false;

  bool get active =>
      categoryId != null ||
      sectionId != null ||
      ageGroup != null ||
      live != null ||
      missing != null ||
      anyAudio;

  bool matches(DuaModel d, CategoryController c) {
    if (sectionId != null && !d.subCategoryIds.contains(sectionId)) return false;
    if (categoryId != null &&
        !d.subCategoryIds
            .any((id) => c.sectionById(id)?.categoryId == categoryId)) {
      return false;
    }
    if (ageGroup != null && !d.shownTo(ageGroup!)) return false;
    if (live != null && d.isEnabled != live) return false;
    if (missing != null && !d.missingAudio.contains(missing)) return false;
    if (anyAudio && d.missingAudio.isEmpty) return false;
    return true;
  }
}

class DuasTab extends StatefulWidget {
  const DuasTab({super.key, this.initialFilter});
  final DuaFilter? initialFilter;

  @override
  State<DuasTab> createState() => _DuasTabState();
}

class _DuasTabState extends State<DuasTab> {
  String _query = '';
  late final DuaFilter _filter = widget.initialFilter ?? DuaFilter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CategoryController>(
        builder: (categories) => GetBuilder<DuaController>(
          builder: (duaController) {
            final all = duaController.allDuas;
            final filtered = filterBySearch(
              [for (final d in all) if (_filter.matches(d, categories)) d],
              _query,
              duaSearchFields,
            );
            final live = all.where((d) => d.isEnabled).length;
            final missing =
                all.where((d) => d.missingRecitations.isNotEmpty).length;

            return AdminPage(
              scroll: false,
              title: 'Duas',
              subtitle:
                  '${formatCount(all.length)} duas · ${formatCount(live)} live · '
                  '${formatCount(missing)} missing a recitation',
              actions: [
                AdminButton.secondary(
                  label: 'Audio coverage',
                  icon: Icons.graphic_eq_rounded,
                  onPressed: () =>
                      Get.find<ShellController>().go(PanelTab.audio),
                ),
                AdminButton(
                  label: 'New dua',
                  icon: Icons.add_rounded,
                  onPressed: () => pushPage(context,
                      DuaEditor(sectionId: _filter.sectionId)),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminSearchField(
                    hint: 'Search by any language, id, benefits or notes',
                    matchCount: filtered.length,
                    totalCount: all.length,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: Space.md),
                  _filters(categories),
                  const SizedBox(height: Space.lg),
                  Expanded(
                    child: AdminTable(
                      columns: const [
                        TableCol('Dua', flex: 5),
                        TableCol('Sections', flex: 3),
                        TableCol('Ages', width: 64),
                        TableCol('Recordings', width: 236),
                        TableCol('Status', width: 96),
                        TableCol('', width: 88),
                      ],
                      rowCount: filtered.length,
                      onRowTap: (i) =>
                          pushPage(context, DuaEditor(dua: filtered[i])),
                      empty: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: duaController.loaded
                            ? 'No duas match'
                            : 'Loading duas…',
                        message: duaController.loaded
                            ? 'Try a different search or clear the filters.'
                            : null,
                      ),
                      rowBuilder: (i) => _row(filtered[i], categories),
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

  List<Widget> _row(DuaModel d, CategoryController categories) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
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
      Padding(
        padding: const EdgeInsets.only(right: Space.md),
        child: Text(
          d.subCategoryIds.isEmpty
              ? 'No section'
              : d.subCategoryIds.map(categories.sectionPath).join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: d.subCategoryIds.isEmpty ? Palette.danger : Palette.textMuted,
          ),
        ),
      ),
      AgeDots(shownTo: d.shownTo),
      AudioBadges(d),
      Align(
        alignment: Alignment.centerLeft,
        child: StatusChip(d.isEnabled ? 'Live' : 'Hidden',
            tone: d.isEnabled ? Tone.success : Tone.neutral),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AudioPlayButton(url: d.grownUpsAudio, tooltip: 'Play Grown-ups'),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => pushPage(context, DuaEditor(dua: d)),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    ];
  }

  Widget _filters(CategoryController c) {
    final sections =
        _filter.categoryId == null ? c.allSubCategories : c.sectionsOf(_filter.categoryId!);
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Dropdown<String>(
          hint: 'All categories',
          value: _filter.categoryId,
          items: {for (final cat in c.allCategories) cat.id: cat.title},
          onChanged: (v) => setState(() {
            _filter.categoryId = v;
            _filter.sectionId = null;
          }),
        ),
        _Dropdown<String>(
          hint: 'All sections',
          value: _filter.sectionId,
          items: {for (final s in sections) s.id: s.title},
          onChanged: (v) => setState(() => _filter.sectionId = v),
        ),
        _Dropdown<AgeGroup>(
          hint: 'All ages',
          value: _filter.ageGroup,
          items: {for (final g in AgeGroup.values) g: g.label},
          onChanged: (v) => setState(() => _filter.ageGroup = v),
        ),
        _Dropdown<bool>(
          hint: 'Live and hidden',
          value: _filter.live,
          items: const {true: 'Live only', false: 'Hidden only'},
          onChanged: (v) => setState(() => _filter.live = v),
        ),
        _Dropdown<String>(
          hint: 'Any recordings',
          value: _filter.anyAudio ? 'any' : _filter.missing?.name,
          items: {
            'any': 'Missing any recording',
            for (final s in AudioSlot.values) s.name: 'Missing ${s.label}',
          },
          onChanged: (v) => setState(() {
            _filter.anyAudio = v == 'any';
            _filter.missing =
                AudioSlot.values.firstWhereOrNull((s) => s.name == v);
          }),
        ),
        if (_filter.active)
          AdminButton.ghost(
            label: 'Clear filters',
            icon: Icons.filter_alt_off_rounded,
            dense: true,
            onPressed: () => setState(() {
              _filter
                ..categoryId = null
                ..sectionId = null
                ..ageGroup = null
                ..live = null
                ..missing = null
                ..anyAudio = false;
            }),
          ),
      ],
    );
  }
}

/// A compact dropdown whose first entry clears the filter.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = value != null && items.containsKey(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: active ? Palette.brandSoft : Palette.card,
        borderRadius: Radii.smAll,
        border: Border.all(color: active ? Palette.brand : Palette.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: active ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isDense: true,
          borderRadius: Radii.smAll,
          style: TextStyle(color: Palette.text, fontSize: 13),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(hint)),
            for (final e in items.entries)
              DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
