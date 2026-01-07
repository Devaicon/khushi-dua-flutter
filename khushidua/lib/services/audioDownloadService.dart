import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { pending, downloading, completed, failed }

class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String title;
  DownloadStatus status;
  double progress;

  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.title,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
  });
}

class AudioDownloadService extends GetxService {
  final RxList<DownloadTask> tasks = <DownloadTask>[].obs;
  bool _isDownloading = false;
  final RxDouble totalProgress = 0.0.obs;
  final RxInt completedCount = 0.obs;
  final RxInt failedCount = 0.obs;
  final RxString currentStatusMessage = "Idle".obs;

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
    _prepareTasks();
    _processQueue();
  }

  void stopAutoDownload() {
    _isDownloading = false;
    currentStatusMessage.value = "Stopped";
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (SDK 33+), we don't need storage permission for app-specific directories
      // but for earlier versions we might. Using path_provider's getApplicationDocumentsDirectory
      // usually doesn't require explicit permissions on modern Android for the app's own files.
      // However, it's safer to check or just use the app-specific dir.
      return true;
    }
    if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  void _prepareTasks() {
    final duaController = Get.find<DuaController>();
    final themeController = Get.find<ThemeController>();
    final ageGroup = themeController.selectedAgeGroup;

    tasks.clear();
    for (var dua in duaController.allDuas) {
      String url = "";
      String suffix = "";
      if (ageGroup == 0) {
        url = dua.littleKidsAudio;
        suffix = "little";
      } else if (ageGroup == 1) {
        url = dua.olderKidsAudio;
        suffix = "older";
      } else {
        url = dua.grownUpsAudio;
        suffix = "grown";
      }

      if (url.isNotEmpty) {
        final fileName = "dua_${dua.id}_$suffix.mp3";
        tasks.add(
          DownloadTask(
            id: dua.id,
            url: url,
            fileName: fileName,
            title: dua.english, // Use English name for display in downloads
          ),
        );
      }
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
        break;
      }

      await _downloadFile(nextTask);
      _updateCounts();

      // Small delay between downloads to be "slow" and non-hindering
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _downloadFile(DownloadTask task) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${task.fileName}";
    final file = File(filePath);

    if (await file.exists()) {
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      return;
    }

    task.status = DownloadStatus.downloading;
    currentStatusMessage.value = "Downloading ${task.title}...";

    try {
      final response = await http.get(Uri.parse(task.url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
      } else {
        task.status = DownloadStatus.failed;
      }
    } catch (e) {
      debugPrint("Download failed for ${task.id}: $e");
      task.status = DownloadStatus.failed;
    }
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

  Future<String?> getLocalPath(String duaId, int ageGroup) async {
    String suffix = ageGroup == 0
        ? "little"
        : ageGroup == 1
        ? "older"
        : "grown";
    final fileName = "dua_${duaId}_$suffix.mp3";
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
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
    if (totalSize < 1024 * 1024) {
      return "${(totalSize / 1024).toStringAsFixed(1)} KB";
    } else {
      return "${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
  }
}
