import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/historyController.dart';
import '../../controllers/mlSettingsController.dart';
import '../../helpers/auditDiff.dart';
import '../../models/audioSlot.dart';
import '../../models/duaModel.dart';
import '../../services/duaService.dart';
import '../../services/storageService.dart';
import '../../widgets/audioDownloadButton.dart';
import '../../widgets/audioPlayButton.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/sectionPicker.dart';
import '../../widgets/ui.dart';
import 'duaPreview.dart';

/// Creates or edits one dua: its text, translations, recordings and where
/// it appears, with a live preview of the card readers will see.
///
/// Replaces the separate create and edit screens, which differed (only edit
/// could attach translation audio) and made every language mandatory.
class DuaEditor extends StatefulWidget {
  const DuaEditor({super.key, this.dua, this.sectionId});

  /// The dua to edit; null to create one.
  final DuaModel? dua;

  /// For a new dua, the section to put it in.
  final String? sectionId;

  @override
  State<DuaEditor> createState() => _DuaEditorState();
}

class _DuaEditorState extends State<DuaEditor> {
  late final DuaModel _draft;
  final Map<String, TextEditingController> _text = {};
  final Map<AudioSlot, html.File> _files = {};
  bool _dirty = false;
  bool _saving = false;
  bool _downloading = false;
  String _status = 'Saving…';
  bool _showErrors = false;

  bool get _isNew => widget.dua == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.dua?.copy() ?? DuaModel.empty();
    if (_isNew) {
      if (widget.sectionId != null) _draft.subCategoryIds = [widget.sectionId!];
      // New duas go last in their sections.
      final duas = Get.find<DuaController>().allDuas;
      _draft.order = duas.isEmpty ? 0 : duas.last.order + 1;
    }
    for (final l in kContentLanguages) {
      _text[l.field] = TextEditingController(text: _draft.text(l.field));
    }
    _text['transliteration'] =
        TextEditingController(text: _draft.transliteration);
    _text['description'] =
        TextEditingController(text: _draft.description ?? '');
    _text['benefits'] = TextEditingController(text: _draft.benefits ?? '');
    for (final entry in _text.entries) {
      var last = entry.value.text;
      // Listeners also fire when the cursor moves; only a text change counts.
      entry.value.addListener(() {
        if (entry.value.text == last) return;
        last = entry.value.text;
        _onText(entry.key, last);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onText(String field, String value) {
    switch (field) {
      case 'transliteration':
        _draft.transliteration = value;
      case 'description':
        _draft.description = value.trim().isEmpty ? null : value;
      case 'benefits':
        _draft.benefits = value.trim().isEmpty ? null : value.trim();
      default:
        _draft.setText(field, value);
    }
    _touch();
  }

  void _touch() => setState(() => _dirty = true);

  List<String> get _problems => [
        if (_draft.arabic.trim().isEmpty) 'Add the Arabic text.',
        if (_draft.english.trim().isEmpty) 'Add the English translation.',
        if (_draft.subCategoryIds.isEmpty) 'Choose at least one section.',
        if (!AgeGroup.values.any(_draft.shownTo))
          'Show it to at least one age group.',
      ];

  Future<void> _save() async {
    final problems = _problems;
    if (problems.isNotEmpty) {
      setState(() => _showErrors = true);
      CustomSnackbar.show("Can't save yet", problems.join(' '),
          isSuccess: false);
      return;
    }
    setState(() {
      _saving = true;
      _status = 'Saving…';
    });
    try {
      await DuaService().save(
        _draft,
        files: Map.of(_files),
        onStatus: (s) => mounted ? setState(() => _status = s) : null,
      );
      _dirty = false;
      CustomSnackbar.show(
        _isNew ? 'Dua created' : 'Dua saved',
        'Phones will pick it up the next time the app opens.',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      CustomSnackbar.show("Couldn't save", '$e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete this dua?',
      message: '"${_draft.title}" will disappear from every section in the '
          'app. You can restore it from History.',
      confirmLabel: 'Delete dua',
      danger: true,
    );
    if (!ok) return;
    setState(() {
      _saving = true;
      _status = 'Deleting…';
    });
    try {
      await DuaService().delete(widget.dua!);
      _dirty = false;
      CustomSnackbar.show('Dua deleted', 'Restore it from History if needed.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      CustomSnackbar.show("Couldn't delete", '$e', isSuccess: false);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _popAfterConfirm() async {
    final navigator = Navigator.of(context);
    if (!await _confirmDiscard()) return;
    _dirty = false;
    navigator.pop();
  }

  Future<bool> _confirmDiscard() => confirmAction(
        context,
        title: 'Discard your changes?',
        message: 'You have changes to this dua that are not saved.',
        confirmLabel: 'Discard',
        danger: true,
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    final tabs = [
      const Tab(text: 'Text'),
      Tab(
          text:
              'Translations  ${_draft.translationCount}/${kTranslationLanguages.length}'),
      Tab(
          text:
              'Audio  ${AudioSlot.values.where((s) => _draft.hasAudio(s) || _files.containsKey(s)).length}/5'),
      Tab(text: 'Placement  ${_draft.subCategoryIds.length}'),
      if (!wide) const Tab(text: 'Preview'),
    ];
    final views = [
      _textTab(),
      _translationsTab(),
      _audioTab(),
      _placementTab(),
      if (!wide) SingleChildScrollView(child: _preview()),
    ];

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popAfterConfirm();
      },
      child: Scaffold(
        body: Stack(
          children: [
            DefaultTabController(
              length: tabs.length,
              child: AdminPage(
                scroll: false,
                maxWidth: 1440,
                leading: const BackButtonCircle(),
                title: _isNew ? 'New dua' : 'Edit dua',
                subtitle: _isNew
                    ? 'Fill in the text, attach recordings, then choose where it appears.'
                    : _draft.title,
                actions: [
                  if (!_isNew) ...[
                    StatusChip(
                      _draft.isEnabled ? 'Live in the app' : 'Hidden',
                      tone: _draft.isEnabled ? Tone.success : Tone.neutral,
                      icon: _draft.isEnabled
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    AdminButton.secondary(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      onPressed: _saving ? null : _delete,
                    ),
                  ],
                  AdminButton(
                    label: _isNew ? 'Create dua' : 'Save changes',
                    icon: Icons.check_rounded,
                    busy: _saving,
                    onPressed: _isNew || _dirty ? _save : null,
                  ),
                ],
                child: LayoutBuilder(
                  builder: (context, box) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AdminCard(
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            height: box.maxHeight,
                            child: Column(
                              children: [
                                if (_showErrors && _problems.isNotEmpty)
                                  _ProblemBanner(_problems),
                                TabBar(
                                  tabs: tabs,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      for (final v in views)
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(Space.xl),
                                          child: v,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: Space.xl),
                        SizedBox(
                          width: 420,
                          height: box.maxHeight,
                          child: SingleChildScrollView(child: _preview()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_saving) BusyOverlay(message: _status),
          ],
        ),
      ),
    );
  }

  // ---- Text ----------------------------------------------------------------

  Widget _textTab() {
    return ListView(
      children: [
        const FieldLabel('Arabic'),
        TextField(
          controller: _text['arabic'],
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: null,
          minLines: 3,
          style: const TextStyle(fontSize: 24, height: 1.9),
          decoration: InputDecoration(
            hintText: 'بِسْمِ اللَّهِ',
            errorText:
                _showErrors && _draft.arabic.trim().isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(height: Space.xl),
        const FieldLabel('Transliteration'),
        TextField(
          controller: _text['transliteration'],
          maxLines: null,
          minLines: 2,
          style: const TextStyle(fontStyle: FontStyle.italic),
          decoration: const InputDecoration(hintText: 'Bismillah…'),
        ),
        const SizedBox(height: Space.xl),
        const FieldLabel('English translation'),
        TextField(
          controller: _text['english'],
          maxLines: null,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'In the name of Allah…',
            errorText: _showErrors && _draft.english.trim().isEmpty
                ? 'Required'
                : null,
          ),
        ),
        const SizedBox(height: Space.xl),
        const FieldLabel('Benefits & virtues'),
        TextField(
          controller: _text['benefits'],
          maxLines: null,
          minLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Shown under "Benefits & Virtues" on the card. Leave empty to grey it out.',
          ),
        ),
        const SizedBox(height: Space.xl),
        const FieldLabel('Notes for admins'),
        TextField(
          controller: _text['description'],
          maxLines: null,
          minLines: 2,
          decoration: const InputDecoration(
            hintText: 'Source, reference or reminders. Not shown in the app.',
          ),
        ),
      ],
    );
  }

  // ---- Translations ----------------------------------------------------------

  Widget _translationsTab() {
    final others =
        kTranslationLanguages.where((l) => l.field != 'english').toList();
    return ListView(
      children: [
        Text(
          'Readers see the translation in the language they chose in the app; '
          'an empty one falls back to English.',
          style: AdminText.muted,
        ),
        const SizedBox(height: Space.lg),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth > 760 ? 2 : 1;
            final width = (c.maxWidth - Space.lg * (columns - 1)) / columns;
            return Wrap(
              spacing: Space.lg,
              runSpacing: Space.lg,
              children: [
                for (final l in others)
                  SizedBox(
                    width: width,
                    child: TextField(
                      controller: _text[l.field],
                      maxLines: null,
                      textDirection:
                          l.rtl ? TextDirection.rtl : TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: l.label,
                        suffixIcon: _draft.text(l.field).trim().isEmpty
                            ? Tooltip(
                                message: 'Missing: readers see English',
                                child: Icon(Icons.error_outline_rounded,
                                    color: Palette.warning, size: 18),
                              )
                            : Icon(Icons.check_circle_rounded,
                                color: Palette.success, size: 18),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---- Audio -----------------------------------------------------------------

  Future<void> _pick(AudioSlot slot) async {
    final files = await pickFiles(accept: 'audio/*,.mp3');
    if (files.isEmpty) return;
    setState(() => _files[slot] = files.first);
    _touch();
  }

  void _remove(AudioSlot slot) {
    setState(() {
      _files.remove(slot);
      _draft.setAudio(slot, '');
    });
    _touch();
  }

  Future<void> _downloadAll() async {
    setState(() => _downloading = true);
    try {
      await downloadAllRecordings(_draft);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _audioTab() {
    final saved = AudioSlot.values.where((s) => _draft.audio(s).isNotEmpty);
    return ListView(
      children: [
        Text(
          'Readers hear the recitation for the age group they picked on the '
          'home screen; the translations play from their own buttons. Files '
          'upload when you save.',
          style: AdminText.muted,
        ),
        if (saved.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton.secondary(
              label: saved.length == 1
                  ? 'Download the recording'
                  : 'Download all ${saved.length} recordings',
              icon: Icons.download_rounded,
              dense: true,
              busy: _downloading,
              tooltip: 'Saved as <dua id>_<recording>.mp3, the names bulk '
                  'upload reads',
              onPressed: _downloading ? null : _downloadAll,
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        const FieldLabel('Recitation by age group'),
        for (final slot in AudioSlot.values.where((s) => s.isRecitation))
          _audioRow(slot),
        const SizedBox(height: Space.xl),
        const FieldLabel('Translation audio'),
        for (final slot in AudioSlot.values.where((s) => !s.isRecitation))
          _audioRow(slot),
      ],
    );
  }

  Widget _audioRow(AudioSlot slot) {
    final picked = _files[slot];
    final url = _draft.audio(slot);
    final group = slot.isRecitation ? AgeGroup.values[slot.index] : null;
    final hiddenForGroup = group != null && !_draft.shownTo(group);
    final missing = picked == null && url.isEmpty;

    final (String status, Tone tone) = picked != null
        ? ('New file: ${picked.name}', Tone.info)
        : url.isNotEmpty
            ? ('Uploaded', Tone.success)
            : hiddenForGroup
                ? ('Not needed: hidden from ${group.label}', Tone.neutral)
                : ('Missing', Tone.warning);

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding:
          const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      decoration: BoxDecoration(
        color: Palette.raised,
        borderRadius: Radii.smAll,
      ),
      child: Row(
        children: [
          AudioPlayButton(url: url, tooltip: 'Play the saved ${slot.label}'),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(color: tone.color, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            DownloadIconButton(
              tooltip: 'Download the saved ${slot.label}',
              onDownload: () => downloadRecording(_draft.id, slot, url),
            ),
          AdminButton.secondary(
            label: missing ? 'Upload' : 'Replace',
            icon: Icons.upload_rounded,
            dense: true,
            onPressed: () => _pick(slot),
          ),
          if (!missing)
            IconButton(
              tooltip: 'Remove this recording',
              onPressed: () => _remove(slot),
              icon: Icon(Icons.close_rounded, color: Palette.danger),
            ),
        ],
      ),
    );
  }

  // ---- Placement -------------------------------------------------------------

  Widget _placementTab() {
    return ListView(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _draft.isEnabled,
          title: const Text('Shown in the app',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Off hides it everywhere without deleting it.',
              style: AdminText.muted),
          onChanged: (v) {
            setState(() => _draft.isEnabled = v);
            _touch();
          },
        ),
        const SizedBox(height: Space.lg),
        const FieldLabel('Age groups'),
        Wrap(
          spacing: Space.sm,
          children: [
            for (final group in AgeGroup.values)
              FilterChip(
                label: Text(group.label),
                selected: _draft.shownTo(group),
                selectedColor: AgeDots.colorOf(group).withValues(alpha: 0.35),
                checkmarkColor: inkOf(AgeDots.colorOf(group)),
                onSelected: (v) {
                  setState(() => _draft.setShownTo(group, v));
                  _touch();
                },
              ),
          ],
        ),
        if (_showErrors && !AgeGroup.values.any(_draft.shownTo))
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Text('Choose at least one age group.',
                style: TextStyle(color: Palette.danger, fontSize: 12)),
          ),
        const SizedBox(height: Space.xl),
        FieldLabel(
          'Sections',
          trailing: Text('${_draft.subCategoryIds.length} chosen',
              style: AdminText.muted),
        ),
        if (_showErrors && _draft.subCategoryIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text('Choose at least one section.',
                style: TextStyle(color: Palette.danger, fontSize: 12)),
          ),
        SectionPicker(
          selected: _draft.subCategoryIds,
          onChanged: (ids) {
            setState(() => _draft.subCategoryIds = ids);
            _touch();
          },
        ),
        if (!_isNew) ...[
          const SizedBox(height: Space.xl),
          const FieldLabel('Recent changes'),
          _historyList(),
          const SizedBox(height: Space.md),
          SelectableText('Dua id: ${_draft.id}', style: AdminText.mono),
        ],
      ],
    );
  }

  Widget _historyList() {
    return GetBuilder<HistoryController>(
      builder: (history) {
        final entries = history.forDoc(_draft.id).take(5).toList();
        if (!history.available) {
          return Text('History is not available yet.',
              style: AdminText.muted);
        }
        if (entries.isEmpty) {
          return Text('No changes recorded since history began.',
              style: AdminText.muted);
        }
        return Column(
          children: [
            for (final e in entries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, size: 18),
                title: Text('${e.action.verb} ${describeFields(e.fields)}'),
                subtitle: Text('${e.by} · ${relativeTime(e.at)}'),
              ),
          ],
        );
      },
    );
  }

  // ---- Preview ---------------------------------------------------------------

  Widget _preview() {
    return GetBuilder<CategoryController>(
      builder: (categories) => GetBuilder<MLSettingsController>(
        builder: (ml) => DuaPreview(
          dua: _draft,
          pendingAudio: {for (final s in _files.keys) s: _files[s]!.name},
          sectionName: _draft.subCategoryIds.isEmpty
              ? null
              : categories.sectionPath(_draft.subCategoryIds.first),
          practiceEnabled: ml.mlSettings?.practiceEnabled ?? true,
        ),
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner(this.problems);
  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
      color: Palette.danger.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Palette.danger, size: 18),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(problems.join('  '),
                style: TextStyle(color: Palette.danger, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
