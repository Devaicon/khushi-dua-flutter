import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/shellController.dart';
import '../../csv/csvCodec.dart';
import '../../helpers/webFiles.dart';
import '../../models/audioSlot.dart';
import '../../models/duaModel.dart';
import '../../widgets/ui.dart';
import '../category/sectionPage.dart';
import '../duas/bulkAudioDialog.dart';

/// How many live duas have each recording, and where the gaps are.
class AudioCoverageTab extends StatefulWidget {
  const AudioCoverageTab({super.key});

  @override
  State<AudioCoverageTab> createState() => _AudioCoverageTabState();
}

/// Recordings a set of duas has, out of those it needs, per slot.
class Coverage {
  Coverage(Iterable<DuaModel> duas) {
    for (final d in duas) {
      if (!d.isEnabled) continue;
      for (final slot in AudioSlot.values) {
        final needed = !slot.isRecitation || d.shownTo(AgeGroup.values[slot.index]);
        if (!needed) continue;
        total[slot] = (total[slot] ?? 0) + 1;
        if (d.hasAudio(slot)) have[slot] = (have[slot] ?? 0) + 1;
      }
    }
  }

  final Map<AudioSlot, int> have = {};
  final Map<AudioSlot, int> total = {};

  int missing(AudioSlot slot) => (total[slot] ?? 0) - (have[slot] ?? 0);
  bool get complete => AudioSlot.values.every((s) => missing(s) == 0);
  double ratio(AudioSlot slot) =>
      (total[slot] ?? 0) == 0 ? 1 : (have[slot] ?? 0) / total[slot]!;
}

class _AudioCoverageTabState extends State<AudioCoverageTab> {
  bool _gapsOnly = true;

  void _downloadMissing(List<DuaModel> duas, CategoryController c) {
    final rows = <List<String>>[];
    for (final d in duas) {
      if (!d.isEnabled) continue;
      for (final slot in d.missingAudio) {
        rows.add([
          d.id,
          d.title,
          d.subCategoryIds.map(c.sectionPath).join(' | '),
          slot.label,
          '${d.id}_${slot.name}.mp3',
        ]);
      }
    }
    downloadTextFile(
      'missing-recordings.csv',
      encodeCsv(
        ['Dua id', 'Dua', 'Sections', 'Missing recording', 'Name the file'],
        rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CategoryController>(
        builder: (c) => GetBuilder<DuaController>(
          builder: (duaController) {
            final all = duaController.allDuas;
            final overall = Coverage(all);
            final rows = [
              for (final category in c.allCategories)
                for (final section in c.sectionsOf(category.id))
                  (category, section, Coverage(duaController.inSection(section.id))),
            ].where((r) => !_gapsOnly || !r.$3.complete).toList();

            return AdminPage(
              scroll: false,
              title: 'Audio coverage',
              subtitle: 'Recordings on live duas. A recitation is needed only '
                  'for the age groups a dua is shown to.',
              actions: [
                AdminButton.secondary(
                  label: 'Download missing list',
                  icon: Icons.download_rounded,
                  tooltip: 'A spreadsheet of every missing recording, with '
                      'the file name to give it for bulk upload',
                  onPressed: () => _downloadMissing(all, c),
                ),
                AdminButton(
                  label: 'Bulk upload',
                  icon: Icons.upload_file_rounded,
                  onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const BulkAudioDialog(),
                  ),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResponsiveGrid(
                    minTileWidth: 200,
                    children: [
                      for (final slot in AudioSlot.values)
                        AdminCard(
                          padding: const EdgeInsets.all(Space.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.label, style: AdminText.muted),
                              const SizedBox(height: Space.xs),
                              Text(
                                '${overall.have[slot] ?? 0} / ${overall.total[slot] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: Space.sm),
                              ProgressBar(
                                value: overall.ratio(slot),
                                color: overall.missing(slot) == 0
                                    ? Palette.success
                                    : Palette.warning,
                              ),
                              const SizedBox(height: Space.xs),
                              Text(
                                overall.missing(slot) == 0
                                    ? 'Complete'
                                    : '${overall.missing(slot)} missing',
                                style: AdminText.muted,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Row(
                    children: [
                      Text(
                        _gapsOnly
                            ? '${rows.length} sections with gaps'
                            : '${rows.length} sections',
                        style: AdminText.cardTitle,
                      ),
                      const Spacer(),
                      const Text('Only sections with gaps', style: AdminText.muted),
                      Switch(
                        value: _gapsOnly,
                        onChanged: (v) => setState(() => _gapsOnly = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Expanded(
                    child: AdminTable(
                      columns: [
                        const TableCol('Section', flex: 4),
                        for (final s in AudioSlot.values)
                          TableCol(s.shortLabel),
                      ],
                      rowCount: rows.length,
                      onRowTap: (i) =>
                          pushPage(context, SectionPage(sectionId: rows[i].$2.id)),
                      empty: const EmptyState(
                        icon: Icons.verified_rounded,
                        title: 'Every section has all its recordings',
                      ),
                      rowBuilder: (i) {
                        final (category, section, cov) = rows[i];
                        return [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(section.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(category.title, style: AdminText.muted),
                            ],
                          ),
                          for (final slot in AudioSlot.values)
                            _cell(cov, slot),
                        ];
                      },
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

  Widget _cell(Coverage cov, AudioSlot slot) {
    final total = cov.total[slot] ?? 0;
    if (total == 0) return const Text('–', style: AdminText.muted);
    final missing = cov.missing(slot);
    return Row(
      children: [
        Icon(
          missing == 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: missing == 0 ? Palette.success : Palette.warning,
        ),
        const SizedBox(width: 6),
        Text(
          '${cov.have[slot] ?? 0}/$total',
          style: TextStyle(
            color: missing == 0 ? Palette.text : Palette.warning,
            fontWeight: missing == 0 ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
