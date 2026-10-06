import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/theme.dart';
import '../../services/audioDownloadService.dart';

/// Download Manager: the four audio groups, each downloaded whole.
///
/// Per-dua selection and the "background downloading" switch are gone: every
/// download now runs in the background natively, and a group is the unit
/// people actually want offline.
class AudioDownloadSettings extends StatefulWidget {
  const AudioDownloadSettings({super.key});

  @override
  State<AudioDownloadSettings> createState() => _AudioDownloadSettingsState();
}

class _AudioDownloadSettingsState extends State<AudioDownloadSettings> {
  final AudioDownloadService _service = Get.find<AudioDownloadService>();
  int? _storageUsed;

  static const Map<AudioType, (IconData, Color)> _looks = {
    AudioType.littleKids: (Icons.child_care_rounded, Color(0xFFF06292)),
    AudioType.olderKids: (Icons.school_rounded, Color(0xFF64B5F6)),
    AudioType.grownUps: (Icons.person_rounded, Color(0xFF4DB6AC)),
    AudioType.english: (Icons.translate_rounded, Color(0xFF7986CB)),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.refresh();
    _updateStorage();
    await _service.measureGroups();
  }

  Future<void> _updateStorage() async {
    final used = await _service.storageUsed();
    if (mounted) setState(() => _storageUsed = used);
  }

  Future<void> _confirmRemove(AudioType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove downloaded audio?".tr),
        content: Text(_service.groupLabel(type)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: Text("Remove".tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.removeGroup(type);
    _updateStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.page,
      appBar: AppBar(title: Text("Download Manager".tr)),
      body: Obx(() {
        final states = Map.of(_service.state);
        // Keeps the storage figure in step as files land.
        _scheduleStorageUpdate(
          states.values.fold<int>(0, (n, s) => n + s.done),
        );

        return ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            _buildIntro(),
            const SizedBox(height: AppSpace.lg),
            for (final type in AudioDownloadService.groups) ...[
              _buildGroup(type, states[type]!),
              const SizedBox(height: AppSpace.md),
            ],
          ],
        );
      }),
    );
  }

  int? _lastDoneTotal;
  void _scheduleStorageUpdate(int doneTotal) {
    if (_lastDoneTotal == doneTotal) return;
    _lastDoneTotal = doneTotal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateStorage());
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: cardDecoration(kBrandNavy),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_download_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Listen offline".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Downloads keep going in the background, even if you close the app."
                      .tr,
                  style: TextStyle(color: AppText.onSurfaceMuted, fontSize: 12),
                ),
                if (_storageUsed != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    "${"Storage used".tr}: ${_service.formatSize(_storageUsed!)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(AudioType type, GroupState group) {
    final (icon, seed) = _looks[type]!;
    final size = group.bytes;
    final details = [
      "${group.done} / ${group.total} ${'duas'.tr}",
      if (size != null && size > 0) _service.formatSize(size),
    ].join("  •  ");

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: plainCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(
                  gradient: AppGradient.forSeed(seed),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _service.groupLabel(type),
                      style: TextStyle(
                        color: rbluedark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        color: AppText.onPageMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _buildAction(type, group),
            ],
          ),
          if (group.running || (group.done > 0 && !group.complete)) ...[
            const SizedBox(height: AppSpace.md),
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: group.progress,
                minHeight: 6,
                backgroundColor: seed.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(seed.ink),
              ),
            ),
          ],
          if (group.running) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              _speedLine(group),
              style: TextStyle(
                color: seed.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!group.running && group.failed > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              "${group.failed} ${'files failed to download'.tr}",
              style: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// "1.4 MB/s  •  About 3 min left", or "Starting…" until the first files
  /// have landed and there is a speed to quote.
  String _speedLine(GroupState group) {
    if (group.bytesPerSecond <= 0) return "Starting…".tr;
    final speed = "${_service.formatSize(group.bytesPerSecond.round())}/s";
    final left = group.timeLeft;
    if (left == null) return speed;
    final String eta;
    if (left.inSeconds < 60) {
      eta = "Less than a minute left".tr;
    } else if (left.inMinutes < 60) {
      eta = "About @count min left".trParams({
        'count': '${left.inMinutes + (left.inSeconds % 60 >= 30 ? 1 : 0)}',
      });
    } else {
      eta = "About @hours h @minutes min left".trParams({
        'hours': '${left.inHours}',
        'minutes': '${left.inMinutes % 60}',
      });
    }
    return "$speed  •  $eta";
  }

  Widget _buildAction(AudioType type, GroupState group) {
    if (group.running) {
      return TextButton(
        onPressed: () => _service.cancelGroup(type),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
        child: Text("Cancel".tr),
      );
    }
    final download = FilledButton(
      onPressed: group.total == 0 ? null : () => _service.downloadGroup(type),
      style: FilledButton.styleFrom(
        backgroundColor: brandFill,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      child: Text(
        group.failed > 0
            ? "Retry".tr
            : group.done > 0
            ? "Resume".tr
            : "Download".tr,
      ),
    );
    final remove = IconButton(
      tooltip: "Remove".tr,
      onPressed: () => _confirmRemove(type),
      icon: const Icon(Icons.delete_outline_rounded),
      color: AppText.onPageMuted,
    );
    if (group.complete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E9E5B)),
          remove,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [if (group.done > 0) remove, download],
    );
  }
}
