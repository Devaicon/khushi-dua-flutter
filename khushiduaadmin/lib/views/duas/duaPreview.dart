import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/languages.dart';
import '../../constants/theme.dart';
import '../../controllers/panelAudioController.dart';
import '../../models/audioSlot.dart';
import '../../models/duaModel.dart';
import '../../widgets/ui.dart';

/// The dua as the app shows it (khushidua/lib/views/openDuasScreen.dart's
/// DuaTile), for the age group and language picked above it. Listen and the
/// translation buttons play the saved recordings.
class DuaPreview extends StatefulWidget {
  const DuaPreview({
    super.key,
    required this.dua,
    this.pendingAudio = const {},
    this.sectionName,
    this.practiceEnabled = true,
  });

  final DuaModel dua;

  /// Recordings picked but not yet uploaded, by slot, with their file names.
  final Map<AudioSlot, String> pendingAudio;
  final String? sectionName;
  final bool practiceEnabled;

  @override
  State<DuaPreview> createState() => _DuaPreviewState();
}

class _DuaPreviewState extends State<DuaPreview> {
  AgeGroup _group = AgeGroup.grownUps;
  String _language = 'english';

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    final color = AgeDots.colorOf(_group);
    final accent = inkOf(color);
    final translation = dua.text(_language).trim().isNotEmpty
        ? dua.text(_language)
        : dua.english;
    final rtl = kContentLanguages
        .firstWhere((l) => l.field == _language)
        .rtl;
    final hidden = !dua.isEnabled || !dua.shownTo(_group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('PREVIEW', style: AdminText.label)),
            DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              isDense: true,
              items: [
                for (final l in kTranslationLanguages)
                  DropdownMenuItem(value: l.field, child: Text(l.label)),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'english'),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        SegmentedButton<AgeGroup>(
          segments: [
            for (final g in AgeGroup.values)
              ButtonSegment(value: g, label: Text(g.label)),
          ],
          selected: {_group},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _group = s.first),
        ),
        const SizedBox(height: Space.md),
        if (hidden)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: StatusChip(
              !dua.isEnabled
                  ? 'Hidden in the app'
                  : '${_group.label} will not see this dua',
              tone: Tone.warning,
              icon: Icons.visibility_off_rounded,
            ),
          ),
        Opacity(
          opacity: hidden ? 0.55 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: Palette.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
              boxShadow: Elevation.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: Radii.pillAll,
                        ),
                        child: Text('Dua 1 of 1',
                            style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      if (widget.sectionName != null)
                        Flexible(
                          child: Text(widget.sectionName!,
                              overflow: TextOverflow.ellipsis,
                              style: AdminText.muted),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  color: color.withValues(alpha: 0.06),
                  child: Text(
                    dua.arabic.trim().isEmpty ? 'Arabic text' : dua.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: dua.arabic.trim().isEmpty
                          ? Palette.textMuted
                          : Palette.text,
                      fontSize: 24,
                      height: 2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dua.transliteration.trim().isNotEmpty) ...[
                        _label('TRANSLITERATION', accent),
                        const SizedBox(height: 8),
                        Text(dua.transliteration,
                            style: TextStyle(
                              color: Palette.text.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            )),
                        const SizedBox(height: 24),
                      ],
                      _label('TRANSLATION', accent),
                      const SizedBox(height: 8),
                      Text(
                        translation.trim().isEmpty ? 'Translation' : translation,
                        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _action(
                          slot: AudioSlot.values[_group.index],
                          icon: Icons.play_arrow_rounded,
                          label: 'Listen',
                          color: accent,
                          filled: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PreviewButton(
                          icon: Icons.mic_none_rounded,
                          label: 'Practice',
                          color: widget.practiceEnabled ? accent : Colors.grey,
                          tooltip: widget.practiceEnabled
                              ? 'Practice is on in the app'
                              : 'Greyed out: switched off in App controls',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PreviewButton(icon: Icons.share_rounded, color: accent),
                    ],
                  ),
                ),
                if (_hasAny(AudioSlot.english) || _hasAny(AudioSlot.urdu))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('TRANSLATION AUDIO', accent),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final slot in [AudioSlot.english, AudioSlot.urdu])
                              if (_hasAny(slot))
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _action(
                                      slot: slot,
                                      icon: Icons.volume_up_rounded,
                                      label: slot == AudioSlot.english
                                          ? 'English'
                                          : 'Urdu',
                                      color: accent,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Palette.line)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 18,
                          color: _hasBenefits ? accent : Colors.grey),
                      const SizedBox(width: 8),
                      Text('Benefits & Virtues',
                          style: TextStyle(
                            color: _hasBenefits ? Palette.text : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _hasBenefits => (widget.dua.benefits ?? '').trim().isNotEmpty;

  bool _hasAny(AudioSlot slot) =>
      widget.dua.hasAudio(slot) || widget.pendingAudio.containsKey(slot);

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 10,
        letterSpacing: 1.5,
      ));

  Widget _action({
    required AudioSlot slot,
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    final url = widget.dua.audio(slot);
    final pending = widget.pendingAudio[slot];
    return GetBuilder<PanelAudioController>(
      builder: (audio) {
        final playing = audio.isPlaying(url);
        final available = url.isNotEmpty;
        return _PreviewButton(
          icon: playing ? Icons.stop_rounded : icon,
          label: playing ? 'Stop' : label,
          color: available || pending != null ? color : Colors.grey,
          filled: filled,
          tooltip: pending != null
              ? '$pending uploads when you save'
              : (available ? null : 'No ${slot.label} recording'),
          onTap: available ? () => audio.toggle(url) : null,
        );
      },
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.icon,
    required this.color,
    this.label,
    this.filled = false,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final bool filled;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    final button = Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      borderRadius: Radii.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.smAll,
        child: SizedBox(
          height: 44,
          width: label == null ? 44 : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
