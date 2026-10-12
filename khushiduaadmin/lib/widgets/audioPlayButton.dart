import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';
import '../controllers/panelAudioController.dart';

/// Plays [url] in the panel; a dimmed icon when there is no recording.
class AudioPlayButton extends StatelessWidget {
  const AudioPlayButton({
    super.key,
    required this.url,
    this.tooltip,
    this.size = 20,
    this.color = Palette.brand,
  });

  final String url;
  final String? tooltip;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PanelAudioController>(
      builder: (audio) {
        final playing = audio.isPlaying(url);
        final failed = url.isNotEmpty && audio.failed == url;
        final Widget icon;
        if (playing && audio.loading) {
          icon = SizedBox.square(
            dimension: size - 4,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          );
        } else {
          icon = Icon(
            failed
                ? Icons.error_outline_rounded
                : (playing
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_fill_rounded),
            size: size + 4,
            color: url.isEmpty
                ? Palette.line
                : (failed ? Palette.danger : color),
          );
        }
        return IconButton(
          tooltip: url.isEmpty
              ? 'No recording'
              : failed
                  ? "Couldn't play this recording"
                  : (tooltip ?? (playing ? 'Stop' : 'Play')),
          onPressed: url.isEmpty ? null : () => audio.toggle(url),
          icon: icon,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
