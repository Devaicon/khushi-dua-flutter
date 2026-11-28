import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:khushidua/controllers/userController.dart';
import 'package:khushidua/services/audioDownloadService.dart';

class AudioController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final RxString _currentlyPlayingPath = "".obs;
  final RxString _currentlyPlayingDuaId = "".obs;
  final RxBool _isPlaying = false.obs;

  String get currentlyPlayingPath => _currentlyPlayingPath.value;
  String get currentlyPlayingDuaId => _currentlyPlayingDuaId.value;
  bool get isPlaying => _isPlaying.value;

  @override
  void onInit() {
    super.onInit();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying.value = state == PlayerState.playing;
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        _currentlyPlayingPath.value = "";
        // Don't clear duaId immediately on stop to allow completion logic
      }
      update();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      final duaId = _currentlyPlayingDuaId.value;
      _currentlyPlayingPath.value = "";
      _currentlyPlayingDuaId.value = "";
      _isPlaying.value = false;
      update();

      if (duaId.isNotEmpty) {
        _markDuaAsDone(duaId);
      }
    });
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> toggleAudio(String path, String duaId) async {
    if (_currentlyPlayingPath.value == path) {
      await stop();
    } else {
      await play(path, duaId);
    }
  }

  Future<void> play(String path, String duaId) async {
    if (path.isEmpty) return;

    await _audioPlayer.stop();
    _currentlyPlayingPath.value = path;
    _currentlyPlayingDuaId.value = duaId;

    try {
      final downloadService = Get.find<AudioDownloadService>();

      final localPath = await downloadService.getLocalPathFromUrl(path);

      if (localPath != null) {
        debugPrint("AudioController: Playing local: $localPath");
        await _audioPlayer.play(DeviceFileSource(localPath));
      } else {
        debugPrint("AudioController: Playing remote: $path");
        await _audioPlayer.play(UrlSource(path));
      }
    } catch (e) {
      debugPrint("AudioController: Error playing audio: $e");
      _currentlyPlayingPath.value = "";
      _currentlyPlayingDuaId.value = "";
    }
    update();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentlyPlayingPath.value = "";
    _currentlyPlayingDuaId.value = "";
    update();
  }

  /// Listening progress is kept on the device, for everyone: no sign-in.
  Future<void> _markDuaAsDone(String duaId) async {
    try {
      await Get.find<UserController>().markListened(duaId);
    } catch (e) {
      debugPrint("AudioController: Error marking dua as done: $e");
    }
  }
}
