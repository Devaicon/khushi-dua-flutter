import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/services/audioDownloadService.dart';

class AudioDownloadSettings extends StatefulWidget {
  const AudioDownloadSettings({super.key});

  @override
  State<AudioDownloadSettings> createState() => _AudioDownloadSettingsState();
}

class _AudioDownloadSettingsState extends State<AudioDownloadSettings> {
  final AudioDownloadService _downloadService =
      Get.find<AudioDownloadService>();
  bool _isAutoDownloadEnabled = false;
  String _storageUsed = "0 KB";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final enabled = await _downloadService.isDownloadsEnabled();
    final storage = await _downloadService.getStorageUsed();
    setState(() {
      _isAutoDownloadEnabled = enabled;
      _storageUsed = storage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Audio Downloads".tr,
          style: const TextStyle(
            color: rblack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: rblack,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        final tasks = _downloadService.tasks;
        final completed = _downloadService.completedCount.value;
        final total = tasks.length;
        final progress = _downloadService.totalProgress.value;
        final statusMessage = _downloadService.currentStatusMessage.value;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(progress, completed, total, statusMessage),
                    const SizedBox(height: 24),
                    _buildAutoDownloadToggle(),
                    const SizedBox(height: 32),
                    const Text(
                      "Verses Download Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rblack,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = tasks[index];
                  return _buildTaskTile(task);
                }, childCount: tasks.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      }),
    );
  }

  Widget _buildStatusCard(
    double progress,
    int completed,
    int total,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4A3AFF), Color(0xff9E8DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff4A3AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.download_for_offline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "$completed of $total verses downloaded",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$message • $_storageUsed used",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDownloadToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          "Auto-Download Verses",
          style: TextStyle(fontWeight: FontWeight.bold, color: rblack),
        ),
        subtitle: const Text(
          "Download audio automatically for offline access",
          style: TextStyle(fontSize: 12),
        ),
        value: _isAutoDownloadEnabled,
        activeColor: const Color(0xff4A3AFF),
        onChanged: (val) async {
          setState(() {
            _isAutoDownloadEnabled = val;
          });
          await _downloadService.setDownloadsEnabled(val);
        },
      ),
    );
  }

  Widget _buildTaskTile(DownloadTask task) {
    IconData icon;
    Color iconColor;
    Widget trailing;

    switch (task.status) {
      case DownloadStatus.completed:
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        trailing = const Icon(Icons.check_circle, color: Colors.green);
        break;
      case DownloadStatus.downloading:
        icon = Icons.cloud_download_outlined;
        iconColor = const Color(0xff4A3AFF);
        trailing = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xff4A3AFF)),
          ),
        );
        break;
      case DownloadStatus.failed:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        trailing = const Icon(Icons.refresh, color: Colors.grey);
        break;
      case DownloadStatus.pending:
        icon = Icons.access_time;
        iconColor = Colors.grey;
        trailing = const Text(
          "Waiting",
          style: TextStyle(fontSize: 10, color: Colors.grey),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.status == DownloadStatus.downloading
              ? const Color(0xff4A3AFF).withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: rblack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  task.status.name.capitalizeFirst!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
