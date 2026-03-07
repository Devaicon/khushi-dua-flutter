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
        return "Grown Ups";
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
  final RxDouble totalProgress = 0.0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt failedCount = 0.obs;
  final RxString currentStatusMessage = "Idle".obs;
  final RxString currentlyDownloadingTitle = "".obs;

  static const String DOWNLOADS_ENABLED_KEY = "audio_downloads_enabled";

  @override
  void onInit() {
    super.onInit();
    _checkAndStartDownloads();
  }

  void _checkAndStartDownloads() async {
    if (await isDownloadsEnabled()) {
      // Small delay to ensure other controllers are ready
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
    for (var dua in duaController.allDuas) {
      AudioType type;
      String url = "";
      if (ageGroup == 0) {
        url = dua.littleKidsAudio;
        type = AudioType.littleKids;
      } else if (ageGroup == 1) {
        url = dua.olderKidsAudio;
        type = AudioType.olderKids;
      } else {
        url = dua.grownUpsAudio;
        type = AudioType.grownUps;
      }

      if (url.isNotEmpty) {
        final task = await _createTask(dua, url, type);
        newTasks.add(task);
      }
    }

    // Merge or replace tasks
    tasks.assignAll(newTasks);
    _updateCounts();
  }

  Future<DownloadTask> _createTask(
    DuaModel dua,
    String url,
    AudioType type,
  ) async {
    final suffix = type.name;
    final fileName = "dua_${dua.id}_$suffix.mp3";
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    final file = File(filePath);
    final fileExists = await file.exists();

    int? size;
    if (fileExists) {
      size = await file.length();
    }

    return DownloadTask(
      id: dua.id,
      url: url,
      fileName: fileName,
      title: dua.english,
      type: type,
      status: fileExists ? DownloadStatus.completed : DownloadStatus.pending,
      progress: fileExists ? 1.0 : 0.0,
      sizeInBytes: size,
    );
  }

  Future<void> addToQueue(DuaModel dua, AudioType type, String url) async {
    if (url.isEmpty) return;

    final existing = tasks.firstWhereOrNull(
      (t) => t.id == dua.id && t.type == type,
    );
    if (existing != null && existing.status == DownloadStatus.completed) return;

    final task = await _createTask(dua, url, type);
    if (existing != null) {
      tasks[tasks.indexOf(existing)] = task;
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
    for (var dua in duas) {
      for (var type in types) {
        String url = "";
        switch (type) {
          case AudioType.littleKids:
            url = dua.littleKidsAudio;
            break;
          case AudioType.olderKids:
            url = dua.olderKidsAudio;
            break;
          case AudioType.grownUps:
            url = dua.grownUpsAudio;
            break;
          case AudioType.english:
            url = dua.englishTranslation ?? "";
            break;
          case AudioType.urdu:
            url = dua.urduTranslation ?? "";
            break;
        }
        if (url.isNotEmpty) {
          final task = await _createTask(dua, url, type);
          final existingIndex = tasks.indexWhere(
            (t) => t.id == dua.id && t.type == type,
          );
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

    if (!_isDownloading) {
      _isDownloading = true;
      _processQueue();
    }
    _updateCounts();
  }

  Future<void> _processQueue() async {
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
  }

  Future<void> _downloadFile(DownloadTask task) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${task.fileName}";
    final file = File(filePath);

    if (await file.exists()) {
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.sizeInBytes = await file.length();
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

  Future<bool> isDownloaded(String duaId, AudioType type) async {
    final suffix = type.name;
    final fileName = "dua_${duaId}_$suffix.mp3";
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    return await File(filePath).exists();
  }

  Future<String?> getLocalPathForType(String duaId, AudioType type) async {
    final suffix = type.name;
    final fileName = "dua_${duaId}_$suffix.mp3";
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  Future<String?> getLocalPathFromUrl(String url) async {
    if (url.isEmpty) return null;
    final task = tasks.firstWhereOrNull(
      (t) => t.url == url && t.status == DownloadStatus.completed,
    );
    if (task != null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/${task.fileName}";
      if (await File(filePath).exists()) {
        return filePath;
      }
    }

    // Fallback: check if any file in the directory matches the expected pattern for this URL
    // This is useful if the tasks list was cleared or restarted.
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith(".mp3")) {
        // We don't easily know which URL matches which file without the tasks list
        // unless we store a mapping.
        // For now, the task list is populated on init for auto-downloads.
      }
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
      if (file is File &&
          file.path.contains("dua_") &&
          file.path.endsWith(".mp3")) {
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
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
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

      final getResponse = await http
          .get(Uri.parse(url), headers: {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 3));
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

    // Fetch in parallel chunks
    const chunkSize = 20;
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
