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

  final List<AudioType> _bulkSelectedGroups = [];
  final Map<AudioType, int> _categorySizes = {};
  bool _isLoadingSizes = true;

  // Per-dua selection
  final Set<String> _selectedDuaIds = {};
  final List<AudioType> _duaSelectedTypes = [AudioType.grownUps];
  final TextEditingController _searchController = TextEditingController();
  String _search = "";

  // Background downloading is opt-in; this reflects the stored preference.
  bool _backgroundEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadBackgroundPref();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBackgroundPref() async {
    final enabled = await _downloadService.isDownloadsEnabled();
    if (mounted) setState(() => _backgroundEnabled = enabled);
  }

  List<DuaModel> get _visibleDuas {
    final all = _duaController.allDuas;
    if (_search.trim().isEmpty) return all;
    final query = _search.toLowerCase().trim();
    return all
        .where((d) => d.english.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingSizes = true);
    // Pre-calculate all sizes for categories
    final types = [
      AudioType.littleKids,
      AudioType.olderKids,
      AudioType.grownUps, // This will be labeled as Urdu Translations
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
                          _buildBackgroundToggle(),
                          const SizedBox(height: 24),
                          _buildBulkDownloadSection(),
                          const SizedBox(height: 24),
                          _buildIndividualSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Download duas to play offline".tr,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
            "Bulk Download",
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
                  "Bulk Download",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildBackgroundToggle() {
    return _buildCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Background downloading",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: rblack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _backgroundEnabled
                      ? "Duas download quietly while you use the app."
                      : "Off. Nothing downloads unless you ask for it.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _backgroundEnabled,
            activeColor: const Color(0xff4A3AFF),
            onChanged: (value) async {
              setState(() => _backgroundEnabled = value);
              await _downloadService.setDownloadsEnabled(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualSection() {
    final duas = _visibleDuas;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Individual Duas",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: rblack,
                  ),
                ),
              ),
              if (_selectedDuaIds.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selectedDuaIds.clear),
                  child: const Text("Clear"),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Pick exactly the duas you want offline.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: "Search duas".tr,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: const Color(0xffF8F9FE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "AUDIO TO DOWNLOAD",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AudioType.littleKids,
              AudioType.olderKids,
              AudioType.grownUps,
              AudioType.english,
            ].map(_buildTypeChip).toList(),
          ),
          const SizedBox(height: 16),
          if (duas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _duaController.allDuas.isEmpty
                      ? "Duas are still loading."
                      : "No duas match that search.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: duas.length,
                itemBuilder: (context, index) => _buildDuaRow(duas[index]),
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${_selectedDuaIds.length} dua(s)",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff4A3AFF),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed:
                    (_selectedDuaIds.isEmpty || _duaSelectedTypes.isEmpty)
                    ? null
                    : _startSelectionDownload,
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
                  "Download Selected",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(AudioType type) {
    final isSelected = _duaSelectedTypes.contains(type);
    return ChoiceChip(
      label: Text(_getTypeLabel(type)),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: const Color(0xff4A3AFF),
      backgroundColor: const Color(0xffF8F9FE),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _duaSelectedTypes.remove(type);
          } else {
            _duaSelectedTypes.add(type);
          }
        });
      },
    );
  }

  Widget _buildDuaRow(DuaModel dua) {
    final isSelected = _selectedDuaIds.contains(dua.id);

    // Which of the chosen audio types this dua actually has a recording for.
    final available = _duaSelectedTypes
        .where((type) => _urlFor(dua, type).isNotEmpty)
        .length;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDuaIds.remove(dua.id);
          } else {
            _selectedDuaIds.add(dua.id);
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
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dua.english.isEmpty ? "Untitled dua" : dua.english,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? rblack : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tells the user up front when a recording simply does not exist,
            // instead of silently queueing nothing.
            Text(
              "$available/${_duaSelectedTypes.length}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: available == 0
                    ? Colors.red.shade300
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _urlFor(DuaModel dua, AudioType type) {
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

  void _startSelectionDownload() {
    final selected = _duaController.allDuas
        .where((d) => _selectedDuaIds.contains(d.id))
        .toList();

    final queued = selected
        .expand((d) => _duaSelectedTypes.map((t) => _urlFor(d, t)))
        .where((url) => url.isNotEmpty)
        .length;

    if (queued == 0) {
      Get.snackbar(
        "Nothing to download",
        "None of the selected duas have a recording for those audio types.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    _downloadService.processBulkDownload(selected, _duaSelectedTypes);
    Get.snackbar(
      "Downloads Queued",
      "$queued file(s) queued for offline access.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xff4A3AFF),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
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
    final queued = _duaController.allDuas
        .expand((d) => _bulkSelectedGroups.map((t) => _urlFor(d, t)))
        .where((url) => url.isNotEmpty)
        .length;

    _downloadService.processBulkDownload(
      _duaController.allDuas,
      _bulkSelectedGroups,
    );
    Get.snackbar(
      "Downloads Queued",
      "$queued file(s) queued for offline access.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xff4A3AFF),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
