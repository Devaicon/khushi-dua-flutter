import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/models/duaModel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { pending, downloading, completed, failed }

enum AudioType { littleKids, olderKids, grownUps, english, urdu }

class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String title;
  final AudioType type;
  DownloadStatus status;
  double progress;
  int? sizeInBytes;

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.title,
    required this.type,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.sizeInBytes,
  });

  String get typeLabel {
    switch (type) {
      case AudioType.littleKids:
        return "Little Kids";
      case AudioType.olderKids:
        return "Older Kids";
      case AudioType.grownUps:
        return "Grown-Up's";
      case AudioType.english:
        return "English Translation";
      case AudioType.urdu:
        return "Urdu Translation";
    }
  }
}

class AudioDownloadService extends GetxService {
  final RxList<DownloadTask> tasks = <DownloadTask>[].obs;
  bool _isDownloading = false;
  bool _queueRunning = false;
  final RxDouble totalProgress = 0.0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt failedCount = 0.obs;
  final RxString currentStatusMessage = "Idle".obs;
  final RxString currentlyDownloadingTitle = "".obs;

  static const String DOWNLOADS_ENABLED_KEY = "audio_downloads_enabled";
  static const String DOWNLOADS_FIRST_RUN_KEY = "audio_downloads_first_run";
  // Bumped once so installs that were silently opted in by the old first-run
  // behaviour get switched back off exactly one time.
  static const String DOWNLOADS_OPT_IN_RESET_KEY = "audio_downloads_optin_reset_v1";

  @override
  void onInit() {
    super.onInit();
    _checkAndStartDownloads();
  }

  void _checkAndStartDownloads() async {
    // Downloads are opt-in. Nothing is ever fetched until the user explicitly
    // turns background downloading on or taps a download button, so opening
    // the Download Manager no longer starts pulling hundreds of megabytes.
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool(DOWNLOADS_FIRST_RUN_KEY) ?? true;
    if (isFirstRun) {
      await prefs.setBool(DOWNLOADS_FIRST_RUN_KEY, false);
      await prefs.setBool(DOWNLOADS_ENABLED_KEY, false);
    }

    // Existing installs were opted in without being asked. Clear that once so
    // upgrading users are not still downloading in the background.
    if (!(prefs.getBool(DOWNLOADS_OPT_IN_RESET_KEY) ?? false)) {
      await prefs.setBool(DOWNLOADS_OPT_IN_RESET_KEY, true);
      await prefs.setBool(DOWNLOADS_ENABLED_KEY, false);
    }

    // Resume only what the user previously opted into.
    if (await isDownloadsEnabled()) {
      Future.delayed(const Duration(seconds: 2), () {
        startAutoDownload();
      });
    }
  }

  Future<AudioDownloadService> init() async {
    return this;
  }

  Future<bool> isDownloadsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(DOWNLOADS_ENABLED_KEY) ?? false;
  }

  Future<void> setDownloadsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DOWNLOADS_ENABLED_KEY, enabled);
    if (enabled) {
      startAutoDownload();
    } else {
      stopAutoDownload();
    }
  }

  Future<void> startAutoDownload() async {
    if (_isDownloading) return;

    // Check permission
    if (!await _checkPermission()) {
      currentStatusMessage.value = "Storage permission required";
      return;
    }

    _isDownloading = true;
    await _prepareAutoTasks();
    _processQueue();
  }

  void stopAutoDownload() {
    _isDownloading = false;
    currentStatusMessage.value = "Stopped";
    currentlyDownloadingTitle.value = "";
  }

  Future<bool> _checkPermission() async {
    return true; // Usually not needed for app-specific documents on modern OS
  }

  Future<void> _prepareAutoTasks() async {
    final duaController = Get.find<DuaController>();
    final themeController = Get.find<ThemeController>();
    final ageGroup = themeController.selectedAgeGroup;

    final List<DownloadTask> newTasks = [];
    final directory = await getApplicationDocumentsDirectory();

    for (var dua in duaController.allDuas) {
      // 1. Current age group selection
      AudioType ageType;
      String ageUrl;
      if (ageGroup == 0) {
        ageUrl = dua.littleKidsAudio;
        ageType = AudioType.littleKids;
      } else if (ageGroup == 1) {
        ageUrl = dua.olderKidsAudio;
        ageType = AudioType.olderKids;
      } else {
        ageUrl = dua.grownUpsAudio;
        ageType = AudioType.grownUps;
      }

      // 1) ALWAYS prioritize Grown-Up's (Urdu Translations)
      if (dua.grownUpsAudio.isNotEmpty) {
        final grownTask = await _createTask(
          dua,
          dua.grownUpsAudio,
          AudioType.grownUps,
          directory,
        );
        if (grownTask.status != DownloadStatus.completed) {
          newTasks.add(grownTask);
        }
      }

      // 2) Then queue the currently selected age-group audio
      // (skip if it is already Grown-Up's)
      if (ageType != AudioType.grownUps && ageUrl.isNotEmpty) {
        final task = await _createTask(dua, ageUrl, ageType, directory);
        if (task.status != DownloadStatus.completed) {
          newTasks.add(task);
        }
      }
    }

    // Merge, never assignAll: a bulk or per-dua selection may already be
    // queued, and replacing the list used to silently discard it.
    for (final task in newTasks) {
      final existing = tasks.indexWhere((t) => t.id == task.id);
      if (existing == -1) {
        tasks.add(task);
      } else if (tasks[existing].status != DownloadStatus.completed) {
        tasks[existing] = task;
      }
    }
    _updateCounts();
  }

  Future<DownloadTask> _createTask(
    DuaModel dua,
    String url,
    AudioType type, [
    Directory? directory,
  ]) async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    final fileName = fileNameFor(dua.id, type);
    final file = File("${dir.path}/$fileName");
    final exists = await file.exists();

    return DownloadTask(
      id: "${dua.id}_${type.name}",
      url: url,
      fileName: fileName,
      title: "${dua.english} (${_getTypeLabel(type)})",
      type: type,
      status: exists ? DownloadStatus.completed : DownloadStatus.pending,
      progress: exists ? 1.0 : 0.0,
      sizeInBytes: exists ? await file.length() : null,
    );
  }

  String _getTypeLabel(AudioType type) {
    switch (type) {
      case AudioType.littleKids:
        return "Little Kids".tr;
      case AudioType.olderKids:
        return "Older Kids".tr;
      case AudioType.grownUps:
        return "Grown-Up's".tr;
      case AudioType.english:
        return "English Translation".tr;
      case AudioType.urdu:
        return "Urdu Translation".tr;
    }
  }

  Future<void> addToQueue(DuaModel dua, AudioType type, String url) async {
    if (url.isEmpty) return;

    final taskId = "${dua.id}_${type.name}";
    final existingIndex = tasks.indexWhere((t) => t.id == taskId);

    if (existingIndex != -1 &&
        tasks[existingIndex].status == DownloadStatus.completed) {
      return;
    }

    final task = await _createTask(dua, url, type);
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }

    if (!_isDownloading) {
      _isDownloading = true;
      _processQueue();
    }
    _updateCounts();
  }

  Future<void> processBulkDownload(
    List<DuaModel> duas,
    List<AudioType> types,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    for (var dua in duas) {
      for (var type in types) {
        String url = _getUrlForType(dua, type);
        if (url.isNotEmpty) {
          final taskId = "${dua.id}_${type.name}";
          final task = await _createTask(dua, url, type, directory);
          final existingIndex = tasks.indexWhere((t) => t.id == taskId);

          if (existingIndex != -1) {
            if (tasks[existingIndex].status != DownloadStatus.completed) {
              tasks[existingIndex] = task;
            }
          } else {
            tasks.add(task);
          }
        }
      }
    }
    _isDownloading = true;
    _processQueue();
    _updateCounts();
  }

  Future<void> _processQueue() async {
    // Only one worker may drain the queue. Bulk download used to call this
    // while auto-download was already looping, so two workers raced for the
    // same task and downloaded it twice.
    if (_queueRunning) return;
    _queueRunning = true;

    while (_isDownloading) {
      DownloadTask? nextTask;
      try {
        nextTask = tasks.firstWhere((t) => t.status == DownloadStatus.pending);
      } catch (e) {
        // No more pending tasks
        _isDownloading = false;
        currentStatusMessage.value = "All downloads completed";
        currentlyDownloadingTitle.value = "";
        break;
      }

      await _downloadFile(nextTask);
      _updateCounts();

      // Small delay between downloads to be "slow" and non-hindering
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _queueRunning = false;
  }

  /// url -> local file name, persisted so playback can find a file that was
  /// downloaded in an earlier session (the in-memory task list starts empty).
  static const String URL_INDEX_KEY = "audio_url_index";
  Map<String, String>? _urlIndex;

  Future<Map<String, String>> _loadUrlIndex() async {
    if (_urlIndex != null) return _urlIndex!;
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(URL_INDEX_KEY) ?? [];
    _urlIndex = {};
    for (final entry in entries) {
      final split = entry.indexOf('|');
      if (split > 0) {
        _urlIndex![entry.substring(0, split)] = entry.substring(split + 1);
      }
    }
    return _urlIndex!;
  }

  Future<void> _rememberUrl(String url, String fileName) async {
    final index = await _loadUrlIndex();
    if (index[url] == fileName) return;
    index[url] = fileName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      URL_INDEX_KEY,
      index.entries.map((e) => "${e.key}|${e.value}").toList(),
    );
  }

  Future<void> _downloadFile(DownloadTask task) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${task.fileName}";
    final file = File(filePath);

    if (await file.exists()) {
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.sizeInBytes = await file.length();
      await _rememberUrl(task.url, task.fileName);
      return;
    }

    task.status = DownloadStatus.downloading;
    currentlyDownloadingTitle.value = "${task.title} (${task.typeLabel})";
    currentStatusMessage.value = "Downloading...";

    try {
      final response = await http.get(Uri.parse(task.url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        task.sizeInBytes = response.bodyBytes.length;
        await _rememberUrl(task.url, task.fileName);
      } else {
        task.status = DownloadStatus.failed;
      }
    } catch (e) {
      debugPrint("Download failed for ${task.id} (${task.type}): $e");
      task.status = DownloadStatus.failed;
    }
    tasks.refresh(); // Trigger GetX update
  }

  void _updateCounts() {
    completedCount.value = tasks
        .where((t) => t.status == DownloadStatus.completed)
        .length;
    failedCount.value = tasks
        .where((t) => t.status == DownloadStatus.failed)
        .length;
    if (tasks.isNotEmpty) {
      totalProgress.value = completedCount.value / tasks.length;
    }
  }

  /// The single source of truth for on-disk naming. Everything that writes or
  /// looks up a cached file must go through this — the two used to disagree
  /// (`dua_<id>_<type>.mp3` was looked up, `<id>_<type>.mp3` was written), so
  /// no cached file was ever found and audio always re-streamed.
  String fileNameFor(String duaId, AudioType type) => "${duaId}_${type.name}.mp3";

  Future<bool> isDownloaded(String duaId, AudioType type) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${fileNameFor(duaId, type)}";
    return await File(filePath).exists();
  }

  Future<String?> getLocalPathForType(String duaId, AudioType type) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${fileNameFor(duaId, type)}";
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  Future<String?> getLocalPathFromUrl(String url) async {
    if (url.isEmpty) return null;
    final directory = await getApplicationDocumentsDirectory();

    // Fast path: a task from this session.
    final task = tasks.firstWhereOrNull(
      (t) => t.url == url && t.status == DownloadStatus.completed,
    );
    if (task != null) {
      final filePath = "${directory.path}/${task.fileName}";
      if (await File(filePath).exists()) return filePath;
    }

    // Persisted path: downloaded in an earlier session, so `tasks` is empty.
    final index = await _loadUrlIndex();
    final fileName = index[url];
    if (fileName != null) {
      final filePath = "${directory.path}/$fileName";
      if (await File(filePath).exists()) return filePath;
    }

    return null;
  }

  Future<String?> getLocalPath(String duaId, int ageGroup) async {
    AudioType type = ageGroup == 0
        ? AudioType.littleKids
        : ageGroup == 1
        ? AudioType.olderKids
        : AudioType.grownUps;
    return getLocalPathForType(duaId, type);
  }

  Future<String> getStorageUsed() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    int totalSize = 0;
    for (var file in files) {
      if (file is File && file.path.endsWith(".mp3")) {
        totalSize += await file.length();
      }
    }
    return formatSize(totalSize);
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  final Map<String, int> _remoteSizeCache = {};
  bool _isCacheLoaded = false;

  Future<void> _loadSizeCache() async {
    if (_isCacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getStringList('remote_size_cache') ?? [];
      for (var item in cachedData) {
        final parts = item.split('|');
        if (parts.length == 2) {
          _remoteSizeCache[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
    } catch (e) {
      debugPrint("Error loading size cache: $e");
    }
    _isCacheLoaded = true;
  }

  Future<void> _saveSizeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _remoteSizeCache.entries
          .map((e) => "${e.key}|${e.value}")
          .toList();
      await prefs.setStringList('remote_size_cache', list);
    } catch (e) {
      debugPrint("Error saving size cache: $e");
    }
  }

  int? getRemoteFileSizeCached(String url) {
    return _remoteSizeCache[url];
  }

  Future<int?> getRemoteFileSize(String url) async {
    if (url.isEmpty) return null;
    await _loadSizeCache();
    if (_remoteSizeCache.containsKey(url)) return _remoteSizeCache[url];

    try {
      // First try HEAD request with longer timeout
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10)); // Increased from 3s

      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          final size = int.tryParse(contentLength);
          if (size != null) {
            _remoteSizeCache[url] = size;
            _saveSizeCache();
            return size;
          }
        }
      }

      // Fallback to GET with Range header if HEAD fails or doesn't return content-length
      final getResponse = await http
          .get(Uri.parse(url), headers: {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 10)); // Increased from 3s

      final rangeHeader = getResponse.headers['content-range'];
      if (rangeHeader != null) {
        final total = rangeHeader.split('/').last;
        final size = int.tryParse(total);
        if (size != null) {
          _remoteSizeCache[url] = size;
          _saveSizeCache();
          return size;
        }
      }
    } on TimeoutException {
      debugPrint("Timeout fetching size for: $url");
      return null;
    } catch (e) {
      debugPrint("Error getting remote file size: $e");
    }
    return null;
  }

  Future<int> getTotalSizeForDuas(
    List<DuaModel> duas,
    List<AudioType> types,
  ) async {
    await _loadSizeCache();
    int total = 0;

    List<String> urlsToFetch = [];
    for (var dua in duas) {
      for (var type in types) {
        String url = _getUrlForType(dua, type);
        if (url.isNotEmpty) {
          if (_remoteSizeCache.containsKey(url)) {
            total += _remoteSizeCache[url]!;
          } else {
            urlsToFetch.add(url);
          }
        }
      }
    }

    if (urlsToFetch.isEmpty) return total;

    // Fetch in parallel chunks - reduced size to prevent congestion
    const chunkSize = 12;
    for (var i = 0; i < urlsToFetch.length; i += chunkSize) {
      final end = (i + chunkSize < urlsToFetch.length)
          ? i + chunkSize
          : urlsToFetch.length;
      final chunk = urlsToFetch.sublist(i, end);
      final results = await Future.wait(
        chunk.map((url) => getRemoteFileSize(url)),
      );
      for (var size in results) {
        if (size != null) total += size;
      }
    }

    return total;
  }

  String _getUrlForType(DuaModel dua, AudioType type) {
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

  Future<void> refreshTasks() async {
    final List<DownloadTask> updatedTasks = [];
    final directory = await getApplicationDocumentsDirectory();

    for (var task in tasks) {
      final filePath = "${directory.path}/${task.fileName}";
      final exists = await File(filePath).exists();

      updatedTasks.add(
        DownloadTask(
          id: task.id,
          url: task.url,
          fileName: task.fileName,
          title: task.title,
          type: task.type,
          status: exists ? DownloadStatus.completed : task.status,
          progress: exists ? 1.0 : task.progress,
          sizeInBytes: exists
              ? await File(filePath).length()
              : task.sizeInBytes,
        ),
      );
    }
    tasks.assignAll(updatedTasks);
    _updateCounts();
  }
}
