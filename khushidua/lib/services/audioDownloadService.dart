import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/models/duaModel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/audioFiles.dart';

enum AudioType { littleKids, olderKids, grownUps, english, urdu }

/// Where one downloadable group stands.
class GroupState {
  const GroupState({
    this.total = 0,
    this.done = 0,
    this.failed = 0,
    this.running = false,
    this.bytes,
    this.downloadedBytes = 0,
    this.bytesPerSecond = 0,
  });

  /// Duas in the group that have a recording.
  final int total;

  /// Of those, how many are saved on this device.
  final int done;

  /// Files that failed in the current run, after their retries.
  final int failed;

  /// True while any of the group's files are queued or downloading.
  final bool running;

  /// Total size of the group's recordings, once known.
  final int? bytes;

  /// Size of the group's recordings already on the device.
  final int downloadedBytes;

  /// Recent download speed while [running]; 0 when nothing has finished in
  /// the last few seconds.
  final double bytesPerSecond;

  /// Time left at the current speed, when both are known.
  Duration? get timeLeft {
    final total = bytes;
    if (!running || total == null || bytesPerSecond <= 0) return null;
    final remaining = (total - downloadedBytes).clamp(0, total);
    return Duration(seconds: (remaining / bytesPerSecond).ceil());
  }

  bool get complete => total > 0 && done >= total;
  double get progress => total == 0 ? 0 : done / total;

  GroupState copyWith({
    int? total,
    int? done,
    int? failed,
    bool? running,
    int? bytes,
    int? downloadedBytes,
    double? bytesPerSecond,
  }) => GroupState(
    total: total ?? this.total,
    done: done ?? this.done,
    failed: failed ?? this.failed,
    running: running ?? this.running,
    bytes: bytes ?? this.bytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
  );
}

/// Downloads dua audio for offline listening, one whole group at a time.
///
/// The downloads run natively (Android WorkManager, iOS background
/// URLSession) through `background_downloader`. They used to run in Dart,
/// one file at a time, and Android 15+ cuts an app's network the moment it
/// leaves the foreground — so a download died as soon as the screen slept or
/// the user switched apps, and every remaining file was marked failed and
/// never retried. Native tasks keep going in the background, run
/// [_maxConcurrent] at a time, retry, and resume a stalled connection.
class AudioDownloadService extends GetxService {
  /// The groups offered in the Download Manager.
  static const List<AudioType> groups = [
    AudioType.littleKids,
    AudioType.olderKids,
    AudioType.grownUps,
    AudioType.english,
  ];

  static const int _maxConcurrent = 8;
  static const String _audioDir = 'audio';

  final RxMap<AudioType, GroupState> state = <AudioType, GroupState>{
    for (final type in groups) type: const GroupState(),
  }.obs;

  StreamSubscription<bd.TaskUpdate>? _updates;
  Directory? _dir;

  /// Bytes finished per group, timestamped, for the speed estimate.
  final Map<AudioType, List<(DateTime, int)>> _finished = {};
  static const Duration _speedWindow = Duration(seconds: 10);
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _updates?.cancel();
    super.onClose();
  }

  Future<void> _start() async {
    try {
      await bd.FileDownloader().configure(
        globalConfig: [
          (bd.Config.holdingQueue, (_maxConcurrent, _maxConcurrent, null)),
          (bd.Config.requestTimeout, const Duration(seconds: 30)),
          (bd.Config.checkAvailableSpace, 50),
        ],
      );
      _updates = bd.FileDownloader().updates.listen(_onUpdate);
      // Delivers what finished while the app was closed, and re-queues tasks
      // the OS killed.
      await bd.FileDownloader().start();
    } catch (e) {
      debugPrint('⬇️ AudioDownloadService: start failed: $e');
    }
    await _removeLegacyFiles();
  }

  Future<Directory> _audioDirectory() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_audioDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  /// Files from the old downloader were named `<duaId>_<type>.mp3` in the
  /// documents folder. Its downloads rarely finished, and the new naming
  /// follows the URL, so they are removed rather than left taking space.
  Future<void> _removeLegacyFiles() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      await for (final entity in docs.list()) {
        if (entity is File && isLegacyAudioFile(entity.uri.pathSegments.last)) {
          await entity.delete();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      for (final key in const [
        'audio_url_index',
        'audio_downloads_enabled',
        'audio_downloads_first_run',
        'audio_downloads_optin_reset_v1',
      ]) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('⬇️ AudioDownloadService: legacy cleanup failed: $e');
    }
  }

  String urlFor(DuaModel dua, AudioType type) {
    switch (type) {
      case AudioType.littleKids:
        return dua.littleKidsAudio;
      case AudioType.olderKids:
        return dua.olderKidsAudio;
      case AudioType.grownUps:
        return dua.grownUpsAudio;
      case AudioType.english:
        return dua.englishTranslation ?? "";
      case AudioType.urdu:
        return dua.urduTranslation ?? "";
    }
  }

  List<String> _urlsFor(AudioType type) => [
    for (final dua in Get.find<DuaController>().allDuas)
      if (urlFor(dua, type).isNotEmpty) urlFor(dua, type),
  ];

  /// Recounts every group from what is on disk and what is still queued.
  /// The disk is the truth: it survives the app being killed mid-download.
  Future<void> refresh() async {
    final dir = await _audioDirectory();
    for (final type in groups) {
      final urls = _urlsFor(type);
      var done = 0;
      var downloadedBytes = 0;
      for (final url in urls) {
        final file = File('${dir.path}/${audioFileNameFor(url)}');
        if (file.existsSync()) {
          done++;
          downloadedBytes += file.lengthSync();
        }
      }
      var running = false;
      try {
        running = (await bd.FileDownloader().allTasks(
          group: type.name,
        )).isNotEmpty;
      } catch (_) {}
      state[type] = state[type]!.copyWith(
        total: urls.length,
        done: done,
        downloadedBytes: downloadedBytes,
        running: running,
        failed: running ? null : 0,
      );
      if (running) _startTicker();
    }
  }

  /// Recomputes the speeds once a second while anything is downloading, so
  /// the figure falls when files stop arriving instead of freezing.
  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      var anyRunning = false;
      for (final type in groups) {
        final group = state[type]!;
        anyRunning |= group.running;
        final speed = group.running ? _speed(type, now) : 0.0;
        if (speed != group.bytesPerSecond) {
          state[type] = group.copyWith(bytesPerSecond: speed);
        }
      }
      if (!anyRunning) {
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  double _speed(AudioType type, DateTime now) {
    final samples = _finished[type];
    if (samples == null || samples.isEmpty) return 0;
    samples.removeWhere((s) => now.difference(s.$1) > _speedWindow);
    if (samples.isEmpty) return 0;
    final bytes = samples.fold<int>(0, (n, s) => n + s.$2);
    // Over the whole window once it has filled; before that, since the
    // first file landed, so the first reading is not ten times too low.
    final span = now.difference(samples.first.$1);
    final seconds = span > const Duration(seconds: 2)
        ? (span < _speedWindow ? span : _speedWindow).inMilliseconds / 1000
        : 2.0;
    return bytes / seconds;
  }

  /// Queues every recording in [type] that is not already on the device.
  Future<void> downloadGroup(AudioType type) async {
    final dir = await _audioDirectory();
    final missing = {
      for (final url in _urlsFor(type))
        if (!File('${dir.path}/${audioFileNameFor(url)}').existsSync()) url,
    };
    if (missing.isEmpty) {
      await refresh();
      return;
    }

    final label = groupLabel(type);
    bd.FileDownloader().configureNotificationForGroup(
      type.name,
      running: bd.TaskNotification(
        label,
        '{numFinished} / {numTotal} ${'downloaded'.tr}',
      ),
      complete: bd.TaskNotification(label, 'Download complete'.tr),
      error: bd.TaskNotification(
        label,
        '{numFailed} ${'files failed to download'.tr}',
      ),
      progressBar: true,
      groupNotificationId: 'audio_${type.name}',
    );

    state[type] = state[type]!.copyWith(running: true, failed: 0);
    _finished[type] = [];
    _startTicker();
    await bd.FileDownloader().enqueueAll([
      for (final url in missing)
        bd.DownloadTask(
          url: url,
          filename: audioFileNameFor(url),
          directory: _audioDir,
          baseDirectory: bd.BaseDirectory.applicationDocuments,
          group: type.name,
          updates: bd.Updates.status,
          retries: 3,
          stallTimeout: const Duration(seconds: 30),
        ),
    ]);
  }

  Future<void> cancelGroup(AudioType type) async {
    await bd.FileDownloader().cancelAll(group: type.name);
    state[type] = state[type]!.copyWith(running: false);
    await refresh();
  }

  /// Deletes the group's files, keeping any shared with another group that
  /// is downloaded (the same recording can serve two age groups).
  Future<void> removeGroup(AudioType type) async {
    await bd.FileDownloader().cancelAll(group: type.name);
    final dir = await _audioDirectory();
    final keep = {
      for (final other in groups)
        if (other != type) ..._urlsFor(other).map(audioFileNameFor),
    };
    for (final url in _urlsFor(type)) {
      final name = audioFileNameFor(url);
      if (keep.contains(name)) continue;
      final file = File('${dir.path}/$name');
      if (await file.exists()) await file.delete();
    }
    await refresh();
  }

  void _onUpdate(bd.TaskUpdate update) {
    if (update is! bd.TaskStatusUpdate) return;
    final type = AudioType.values.firstWhereOrNull(
      (t) => t.name == update.task.group,
    );
    if (type == null || !state.containsKey(type)) return;
    final current = state[type]!;

    switch (update.status) {
      case bd.TaskStatus.complete:
        // The file just written, measured on disk; the cached remote size
        // may not be loaded if the download outlived a restart.
        final file = _dir == null
            ? null
            : File('${_dir!.path}/${update.task.filename}');
        final size = (file != null && file.existsSync())
            ? file.lengthSync()
            : _sizeCache[update.task.url] ?? 0;
        (_finished[type] ??= []).add((DateTime.now(), size));
        state[type] = current.copyWith(
          done: (current.done + 1).clamp(0, current.total),
          downloadedBytes: current.downloadedBytes + size,
        );
      case bd.TaskStatus.failed:
      case bd.TaskStatus.notFound:
        debugPrint(
          '⬇️ ${update.task.filename} failed: ${update.exception?.description}',
        );
        state[type] = current.copyWith(failed: current.failed + 1);
      default:
        break;
    }
    if (update.status.isFinalState) _settle(type);
  }

  /// After a task finishes, checks whether its group has anything left.
  Future<void> _settle(AudioType type) async {
    try {
      final left = await bd.FileDownloader().allTasks(group: type.name);
      if (left.isEmpty) {
        final failed = state[type]!.failed;
        await refresh();
        // refresh() resets the failure count; a finished run keeps it, so
        // the screen can offer a retry.
        state[type] = state[type]!.copyWith(failed: failed);
      }
    } catch (_) {}
  }

  /// The downloaded file for [url], if there is one. Used by playback.
  Future<String?> getLocalPathFromUrl(String url) async {
    if (url.isEmpty) return null;
    final dir = await _audioDirectory();
    final path = '${dir.path}/${audioFileNameFor(url)}';
    return File(path).existsSync() ? path : null;
  }

  String groupLabel(AudioType type) {
    switch (type) {
      case AudioType.littleKids:
        return "Little Kids".tr;
      case AudioType.olderKids:
        return "Older Kids".tr;
      case AudioType.grownUps:
        return "Grown ups".tr;
      case AudioType.english:
        return "English Translation".tr;
      case AudioType.urdu:
        return "Urdu Translation".tr;
    }
  }

  /// Space taken by every downloaded recording.
  Future<int> storageUsed() async {
    final dir = await _audioDirectory();
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  // ---- Group sizes ---------------------------------------------------------

  static const String _sizeCacheKey = 'remote_size_cache';
  final Map<String, int> _sizeCache = {};
  bool _sizeCacheLoaded = false;
  bool _measuring = false;

  /// Fills in each group's size. Sizes are cached across launches, so after
  /// the first time this makes no requests. The old version opened a new
  /// connection per file — hundreds of TLS handshakes racing the downloads —
  /// whereas this reuses one client and keeps a few requests in flight.
  Future<void> measureGroups() async {
    if (_measuring) return;
    _measuring = true;
    final client = http.Client();
    try {
      await _loadSizeCache();
      for (final type in groups) {
        final urls = _urlsFor(type);
        final unknown = urls.where((u) => !_sizeCache.containsKey(u)).toList();
        for (var i = 0; i < unknown.length; i += 6) {
          await Future.wait(
            unknown.skip(i).take(6).map((url) => _measure(client, url)),
          );
        }
        var bytes = 0;
        for (final url in urls) {
          bytes += _sizeCache[url] ?? 0;
        }
        state[type] = state[type]!.copyWith(bytes: bytes);
      }
      await _saveSizeCache();
    } finally {
      client.close();
      _measuring = false;
    }
  }

  Future<void> _measure(http.Client client, String url) async {
    try {
      final response = await client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      final size = int.tryParse(response.headers['content-length'] ?? '');
      if (response.statusCode == 200 && size != null) _sizeCache[url] = size;
    } catch (_) {
      // Unknown sizes are simply left out of the total.
    }
  }

  Future<void> _loadSizeCache() async {
    if (_sizeCacheLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    for (final item in prefs.getStringList(_sizeCacheKey) ?? const []) {
      final split = item.lastIndexOf('|');
      if (split <= 0) continue;
      final size = int.tryParse(item.substring(split + 1));
      if (size != null) _sizeCache[item.substring(0, split)] = size;
    }
    _sizeCacheLoaded = true;
  }

  Future<void> _saveSizeCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sizeCacheKey, [
      for (final e in _sizeCache.entries) '${e.key}|${e.value}',
    ]);
  }
}
