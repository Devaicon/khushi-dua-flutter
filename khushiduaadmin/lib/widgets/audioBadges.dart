import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../models/audioSlot.dart';
import '../models/duaModel.dart';

/// One small tag per recording: filled when uploaded, amber when missing
/// for an age group that sees the dua, faint when not needed.
class AudioBadges extends StatelessWidget {
  const AudioBadges(this.dua, {super.key});
  final DuaModel dua;

  @override
  Widget build(BuildContext context) {
    final missing = dua.missingAudio;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final slot in AudioSlot.values)
          () {
            final has = dua.hasAudio(slot);
            final needed = missing.contains(slot);
            final color = has
                ? Palette.success
                : (needed ? Palette.warning : Palette.textMuted);
            final badge = Tooltip(
              message: '${slot.label}: '
                  '${has ? 'uploaded' : (needed ? 'missing' : 'not needed')}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: has ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withValues(alpha: has ? 0 : (needed ? 0.6 : 0.25)),
                  ),
                ),
                child: Text(
                  slot.shortLabel,
                  style: TextStyle(
                    color: color.withValues(alpha: has || needed ? 1 : 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
            return Padding(padding: const EdgeInsets.only(right: 4), child: badge);
          }(),
      ],
    );
  }
}
