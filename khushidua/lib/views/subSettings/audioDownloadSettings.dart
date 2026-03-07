import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/colors.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/models/duaModel.dart';
import 'package:khushidua/services/audioDownloadService.dart';

class AudioDownloadSettings extends StatefulWidget {
  const AudioDownloadSettings({super.key});

  @override
  State<AudioDownloadSettings> createState() => _AudioDownloadSettingsState();
}

class _AudioDownloadSettingsState extends State<AudioDownloadSettings> {
  final AudioDownloadService _downloadService =
      Get.find<AudioDownloadService>();
  final DuaController _duaController = Get.find<DuaController>();

  String _searchQuery = "";
  final List<AudioType> _bulkSelectedGroups = [];
  final Map<AudioType, int> _categorySizes = {};
  bool _isLoadingSizes = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingSizes = true);
    // Pre-calculate all sizes for categories
    final types = [
      AudioType.littleKids,
      AudioType.olderKids,
      AudioType.grownUps,
      AudioType.english,
    ];

    for (var type in types) {
      final size = await _downloadService.getTotalSizeForDuas(
        _duaController.allDuas,
        [type],
      );
      _categorySizes[type] = size;
    }

    if (mounted) setState(() => _isLoadingSizes = false);
  }

  int get _selectedTotalSize {
    int total = 0;
    for (var type in _bulkSelectedGroups) {
      total += _categorySizes[type] ?? 0;
    }
    return total;
  }

  List<DuaModel> get _filteredDuas {
    if (_searchQuery.isEmpty) return _duaController.allDuas;
    return _duaController.allDuas
        .where(
          (d) =>
              d.english.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.arabic.contains(_searchQuery),
        )
        .toList();
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
          "Download Manager".tr,
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              final tasks = _downloadService.tasks;
              final completed = _downloadService.completedCount.value;
              final total = tasks.length;
              final progress = _downloadService.totalProgress.value;
              final statusMessage = _downloadService.currentStatusMessage.value;
              final currentTitle =
                  _downloadService.currentlyDownloadingTitle.value;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusCard(
                            progress,
                            completed,
                            total,
                            statusMessage,
                            currentTitle,
                          ),
                          const SizedBox(height: 24),
                          _buildBulkDownloadSection(),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Individual Duas",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: rblack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Customize your offline collection",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (_isLoadingSizes)
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 22,
                                      color: Color(0xff4A3AFF),
                                    ),
                                    onPressed: () {
                                      _downloadService.refreshTasks();
                                      _loadInitialData();
                                    },
                                    tooltip: "Refresh sizes and status",
                                  ),
                                ],
                              ),
                            ],
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
                        final dua = _filteredDuas[index];
                        return _buildDuaDownloadTile(dua);
                      }, childCount: _filteredDuas.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffF1F4FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: const InputDecoration(
            icon: Icon(Icons.search, color: Color(0xff4A3AFF)),
            border: InputBorder.none,
            hintText: "Search duas...",
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    double progress,
    int completed,
    int total,
    String message,
    String currentTitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff4A3AFF), Color(0xff2A158F)],
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
              const Icon(
                Icons.cloud_download_rounded,
                color: Colors.white,
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTitle.isNotEmpty ? "DOWNLOADING" : "QUEUE STATUS",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTitle.isNotEmpty
                          ? currentTitle
                          : (total > 0
                                ? "$completed / $total Files Completed"
                                : "Waiting for download selection"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (currentTitle.isNotEmpty)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkDownloadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bulk Selection",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: rblack,
            ),
          ),
          const SizedBox(height: 16),
          _buildBulkGroupRow(AudioType.littleKids),
          _buildBulkGroupRow(AudioType.olderKids),
          _buildBulkGroupRow(AudioType.grownUps),
          _buildBulkGroupRow(AudioType.english),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Selection",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _downloadService.formatSize(_selectedTotalSize),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4A3AFF),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _bulkSelectedGroups.isEmpty
                    ? null
                    : _startBulkDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4A3AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Download Group",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkGroupRow(AudioType type) {
    final isSelected = _bulkSelectedGroups.contains(type);
    final size = _categorySizes[type];

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _bulkSelectedGroups.remove(type);
          } else {
            _bulkSelectedGroups.add(type);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isSelected ? const Color(0xff4A3AFF) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getTypeLabel(type),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? rblack : Colors.grey.shade700,
                ),
              ),
            ),
            if (_isLoadingSizes)
              const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else if (size != null)
              Text(
                _downloadService.formatSize(size),
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? const Color(0xff4A3AFF) : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuaDownloadTile(DuaModel dua) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: const Color(0xff4A3AFF),
        title: Text(
          dua.english,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: rblack,
          ),
        ),
        subtitle: Text(
          dua.arabic,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontFamily: 'arabic',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _buildIndividualTypeRow(
                  dua,
                  AudioType.littleKids,
                  dua.littleKidsAudio,
                ),
                _buildIndividualTypeRow(
                  dua,
                  AudioType.olderKids,
                  dua.olderKidsAudio,
                ),
                _buildIndividualTypeRow(
                  dua,
                  AudioType.grownUps,
                  dua.grownUpsAudio,
                ),
                _buildIndividualTypeRow(
                  dua,
                  AudioType.english,
                  dua.englishTranslation ?? "",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualTypeRow(DuaModel dua, AudioType type, String url) {
    if (url.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: Stream.fromFuture(_downloadService.isDownloaded(dua.id, type)),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                isDownloaded
                    ? Icons.check_circle_rounded
                    : Icons.download_for_offline_outlined,
                color: isDownloaded ? Colors.green : Colors.grey.shade400,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(type),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildSizeLabel(url),
                  ],
                ),
              ),
              if (!isDownloaded)
                InkWell(
                  onTap: () => _downloadService.addToQueue(dua, type, url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff4A3AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Download",
                      style: TextStyle(
                        color: Color(0xff4A3AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  "Saved",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getTypeLabel(AudioType type) {
    switch (type) {
      case AudioType.littleKids:
        return "Little Kids".tr;
      case AudioType.olderKids:
        return "Older Kids".tr;
      case AudioType.grownUps:
        return "Grown Ups".tr;
      case AudioType.english:
        return "English Translation".tr;
      case AudioType.urdu:
        return "Urdu Translation".tr;
    }
  }

  Widget _buildSizeLabel(String url) {
    // Optimized: Check service cache directly first to avoid flickering
    final cachedSize = _downloadService.getRemoteFileSizeCached(url);
    if (cachedSize != null) {
      return Text(
        _downloadService.formatSize(cachedSize),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      );
    }

    return FutureBuilder<int?>(
      future: _downloadService.getRemoteFileSize(url),
      builder: (context, snapshot) {
        final size = snapshot.data;
        if (size == null) {
          return const Text(
            "Calculating...",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          );
        }
        return Text(
          _downloadService.formatSize(size),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        );
      },
    );
  }

  Widget? _buildBottomActionBar() {
    return Obx(() {
      final isDownloading =
          _downloadService.totalProgress.value < 1.0 &&
          _downloadService.tasks.any(
            (t) => t.status != DownloadStatus.completed,
          );
      if (!isDownloading) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Background Download...",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff4A3AFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadService.totalProgress.value,
                        backgroundColor: const Color(0xffF1F4FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xff4A3AFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _downloadService.stopAutoDownload(),
                icon: const Icon(
                  Icons.stop_circle_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _startBulkDownload() {
    _downloadService.processBulkDownload(
      _duaController.allDuas,
      _bulkSelectedGroups,
    );
    Get.snackbar(
      "Downloads Queued",
      "Selected groups are being prepared for offline access.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xff4A3AFF),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
