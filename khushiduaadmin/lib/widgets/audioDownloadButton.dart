import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../helpers/bulkAudio.dart';
import '../helpers/webFiles.dart';
import '../models/audioSlot.dart';
import '../models/duaModel.dart';
import 'customSnackbar.dart';

/// Downloads one saved recording as `<duaId>_<slot>.mp3`, the name bulk
/// upload reads, so the file can go back up unchanged.
Future<void> downloadRecording(String duaId, AudioSlot slot, String url) async {
  if (!await _download(duaId, slot, url)) _showFallbackNote();
}

/// Downloads every saved recording of [dua], one file each.
Future<void> downloadAllRecordings(DuaModel dua) async {
  var fellBack = false;
  for (final slot in AudioSlot.values) {
    final url = dua.audio(slot);
    if (url.isEmpty) continue;
    if (!await _download(dua.id, slot, url)) fellBack = true;
  }
  if (fellBack) _showFallbackNote();
}

/// False when it had to fall back to opening the file in a new tab.
Future<bool> _download(String duaId, AudioSlot slot, String url) async {
  try {
    await downloadUrl(url, (type) => audioDownloadName(duaId, slot, type));
    return true;
  } catch (_) {
    // The fetch is blocked when the bucket's CORS policy does not allow the
    // panel's origin; the browser can still save it from its own player.
    html.window.open(url, '_blank');
    return false;
  }
}

void _showFallbackNote() {
  CustomSnackbar.show(
    'Opened in a new tab',
    "The file couldn't be downloaded directly. Use the player's menu in the "
        'new tab to save it.',
    isSuccess: false,
  );
}

/// A download icon that shows a spinner while [onDownload] runs; dimmed when
/// [onDownload] is null, i.e. there is nothing to download.
class DownloadIconButton extends StatefulWidget {
  const DownloadIconButton({
    super.key,
    required this.tooltip,
    required this.onDownload,
  });

  final String tooltip;
  final Future<void> Function()? onDownload;

  @override
  State<DownloadIconButton> createState() => _DownloadIconButtonState();
}

class _DownloadIconButtonState extends State<DownloadIconButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onDownload!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final none = widget.onDownload == null;
    return IconButton(
      tooltip: none ? 'No recordings' : widget.tooltip,
      onPressed: none || _busy ? null : _run,
      icon: _busy
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Palette.brand,
              ),
            )
          : Icon(
              Icons.download_rounded,
              size: 20,
              color: none ? Palette.line : Palette.textMuted,
            ),
      visualDensity: VisualDensity.compact,
    );
  }
}
