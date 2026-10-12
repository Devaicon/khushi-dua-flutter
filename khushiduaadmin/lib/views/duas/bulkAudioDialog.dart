import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/duaController.dart';
import '../../helpers/bulkAudio.dart';
import '../../services/duaService.dart';
import '../../services/storageService.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';

/// Uploads many recordings at once, each matched to its dua by file name.
///
/// Pick the files, review what each will replace, then upload. Every file
/// becomes an ordinary dua edit, so each can be undone from History.
class BulkAudioDialog extends StatefulWidget {
  const BulkAudioDialog({super.key});

  @override
  State<BulkAudioDialog> createState() => _BulkAudioDialogState();
}

class _BulkAudioDialogState extends State<BulkAudioDialog> {
  List<html.File> _files = [];
  List<AudioFileMatch> _matches = [];
  int? _done;
  bool _uploading = false;

  Future<void> _pick() async {
    final files = await pickFiles(accept: 'audio/*,.mp3,.m4a,.wav', multiple: true);
    if (files.isEmpty) return;
    final duas = Get.find<DuaController>();
    setState(() {
      _files = files;
      _matches = matchAudioFiles(
        [for (final f in files) f.name],
        (id) => duas.byId(id) != null,
      );
      _done = null;
    });
  }

  Future<void> _upload() async {
    final duas = Get.find<DuaController>();
    final items = [
      for (var i = 0; i < _files.length; i++)
        if (_matches[i].ok)
          (dua: duas.byId(_matches[i].duaId!)!, slot: _matches[i].slot!, file: _files[i]),
    ];
    setState(() {
      _uploading = true;
      _done = 0;
    });
    try {
      await DuaService().attachAudio(
        items,
        onProgress: (done, _) => mounted ? setState(() => _done = done) : null,
      );
      CustomSnackbar.show('Recordings uploaded',
          '${items.length} recordings saved. Phones get them on their next launch.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      CustomSnackbar.show(
        'Upload stopped',
        '${_done ?? 0} of ${items.length} were saved before: $e',
        isSuccess: false,
      );
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _matches.where((m) => m.ok).length;
    final bad = _matches.length - ok;
    final duas = Get.find<DuaController>();

    return AlertDialog(
      title: const Text('Bulk upload recordings'),
      content: SizedBox(
        width: 760,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Name each file after its dua id and the recording, e.g. '
              '0tgKka3QG4SmpwiCyVfV_english.mp3. Recordings: littleKids, '
              'olderKids, grownUps, english, urdu. "Download missing list" on '
              'Audio coverage gives every missing file\'s name.',
              style: AdminText.muted,
            ),
            const SizedBox(height: Space.lg),
            if (_matches.isEmpty)
              Expanded(
                child: Center(
                  child: AdminButton(
                    label: 'Choose audio files',
                    icon: Icons.library_music_outlined,
                    onPressed: _pick,
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: Space.sm,
                children: [
                  StatusChip('$ok ready', tone: Tone.success),
                  if (bad > 0) StatusChip('$bad skipped', tone: Tone.danger),
                  if (_done != null)
                    StatusChip('$_done of $ok uploaded', tone: Tone.info),
                ],
              ),
              const SizedBox(height: Space.md),
              Expanded(
                child: ListView.separated(
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final m = _matches[i];
                    final dua = m.duaId == null ? null : duas.byId(m.duaId!);
                    final replaces = m.ok && dua!.hasAudio(m.slot!);
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        m.ok ? Icons.check_circle_rounded : Icons.block_rounded,
                        color: m.ok ? Palette.success : Palette.danger,
                      ),
                      title: Text(m.fileName),
                      subtitle: Text(
                        m.ok
                            ? '${m.slot!.label} of "${dua!.title}"'
                                '${replaces ? ' · replaces the current recording' : ''}'
                            : m.problem!,
                        style: TextStyle(
                          color: m.ok
                              ? (replaces ? Palette.warning : Palette.textMuted)
                              : Palette.danger,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      actions: [
        AdminButton.ghost(
          label: 'Cancel',
          onPressed: _uploading ? null : () => Navigator.of(context).pop(),
        ),
        if (_matches.isNotEmpty)
          AdminButton.secondary(
            label: 'Choose other files',
            onPressed: _uploading ? null : _pick,
          ),
        AdminButton(
          label: ok == 0 ? 'Upload' : 'Upload $ok recordings',
          icon: Icons.cloud_upload_outlined,
          busy: _uploading,
          onPressed: ok == 0 ? null : _upload,
        ),
      ],
    );
  }
}
