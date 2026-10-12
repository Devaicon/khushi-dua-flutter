import 'dart:async';
import 'dart:html' as html;

import 'package:get/get.dart';

/// Plays dua recordings inside the panel, one at a time.
///
/// Recordings used to open in a new browser tab; now a play button anywhere
/// in the panel plays here, and starting one stops the other.
class PanelAudioController extends GetxController {
  final html.AudioElement _player = html.AudioElement()..preload = 'none';
  final List<StreamSubscription> _subs = [];

  /// The URL playing, or loading to play; empty when nothing is.
  String _current = '';
  String get current => _current;

  bool _loading = false;
  bool get loading => _loading;

  /// The URL that last failed to play.
  String _failed = '';
  String get failed => _failed;

  @override
  void onInit() {
    super.onInit();
    _subs
      ..add(_player.onPlaying.listen((_) {
        _loading = false;
        update();
      }))
      ..add(_player.onEnded.listen((_) => _reset()))
      ..add(_player.onError.listen((_) {
        _failed = _current;
        _reset();
      }));
  }

  bool isPlaying(String url) => url.isNotEmpty && url == _current;

  Future<void> toggle(String url) async {
    if (url.isEmpty) return;
    if (isPlaying(url)) {
      stop();
      return;
    }
    _player.pause();
    _current = url;
    _failed = '';
    _loading = true;
    update();
    _player.src = url;
    try {
      await _player.play();
    } catch (_) {
      _failed = url;
      _reset();
    }
  }

  void stop() {
    _player.pause();
    _reset();
  }

  void _reset() {
    _current = '';
    _loading = false;
    update();
  }

  @override
  void onClose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.pause();
    super.onClose();
  }
}
