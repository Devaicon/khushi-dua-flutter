import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/authController.dart';
import '../../controllers/categoryController.dart';
import '../../controllers/contentController.dart';
import '../../controllers/duaController.dart';
import '../../controllers/historyController.dart';
import '../../controllers/mlSettingsController.dart';
import '../../controllers/shellController.dart';
import '../../controllers/userController.dart';
import '../../helpers/auditDiff.dart';
import '../../models/audioSlot.dart';
import '../../widgets/ui.dart';
import '../duas/bulkAudioDialog.dart';
import '../duas/duaEditor.dart';
import 'audioCoverage.dart';

/// What needs doing, and how the app is being used.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Get.find<MLSettingsController>().getMLSettings());
  }

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<ShellController>();
    return Scaffold(
      body: GetBuilder<AuthController>(
        builder: (auth) => GetBuilder<CategoryController>(
          builder: (c) => GetBuilder<DuaController>(
            builder: (d) => GetBuilder<UserController>(
              builder: (u) {
                final duas = d.allDuas;
                final live = duas.where((x) => x.isEnabled).toList();
                final coverage = Coverage(duas);
                final needed = AudioSlot.values
                    .fold<int>(0, (n, s) => n + (coverage.total[s] ?? 0));
                final have = AudioSlot.values
                    .fold<int>(0, (n, s) => n + (coverage.have[s] ?? 0));
                final members = u.allUsers.where((x) => x.isMember).length;
                final name = auth.adminModel.firstName;

                return AdminPage(
                  title: name.isEmpty ? 'Overview' : 'Assalamu alaikum, $name',
                  subtitle: 'Here is how Khushi Dua looks right now.',
                  actions: [
                    AdminButton.secondary(
                      label: 'Bulk upload audio',
                      icon: Icons.upload_file_rounded,
                      onPressed: () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const BulkAudioDialog(),
                      ),
                    ),
                    AdminButton.secondary(
                      label: 'Send notification',
                      icon: Icons.campaign_outlined,
                      onPressed: () => shell.go(PanelTab.notifications),
                    ),
                    AdminButton(
                      label: 'New dua',
                      icon: Icons.add_rounded,
                      onPressed: () => pushPage(context, const DuaEditor()),
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResponsiveGrid(
                        children: [
                          StatTile(
                            label: 'Duas',
                            value: formatCount(duas.length),
                            caption: '${live.length} live · ${duas.length - live.length} hidden',
                            icon: Icons.menu_book_rounded,
                            onTap: () => shell.go(PanelTab.duas),
                          ),
                          StatTile(
                            label: 'Categories',
                            value: '${c.allCategories.length}',
                            caption: '${c.allSubCategories.length} sections',
                            icon: Icons.folder_rounded,
                            color: Palette.olderKids,
                            onTap: () => shell.go(PanelTab.categories),
                          ),
                          StatTile(
                            label: 'Recordings',
                            value: needed == 0 ? '–' : '${(have * 100 / needed).floor()}%',
                            caption: '${needed - have} missing',
                            icon: Icons.graphic_eq_rounded,
                            color: have == needed ? Palette.grownUps : Palette.warning,
                            onTap: () => shell.go(PanelTab.audio),
                          ),
                          StatTile(
                            label: 'Users',
                            value: formatCount(u.allUsers.length),
                            caption: '$members members',
                            icon: Icons.people_rounded,
                            color: Palette.littleKids,
                            onTap: () => shell.go(PanelTab.users),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      LayoutBuilder(
                        builder: (context, box) {
                          final attention = _attention(c, d, shell);
                          final recent = _recent(shell);
                          final listened = _mostListened(d, u);
                          if (box.maxWidth < 900) {
                            return Column(children: [
                              attention,
                              const SizedBox(height: Space.lg),
                              listened,
                              const SizedBox(height: Space.lg),
                              recent,
                            ]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(children: [
                                attention,
                                const SizedBox(height: Space.lg),
                                listened,
                              ])),
                              const SizedBox(width: Space.lg),
                              Expanded(child: recent),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _attention(CategoryController c, DuaController d, ShellController shell) {
    final duas = d.allDuas.where((x) => x.isEnabled);
    final missingRecitation =
        duas.where((x) => x.missingRecitations.isNotEmpty).length;
    final missingTranslation = duas
        .where((x) => !x.hasAudio(AudioSlot.english) || !x.hasAudio(AudioSlot.urdu))
        .length;
    final noSection = d.allDuas
        .where((x) => x.subCategoryIds.where((id) => c.sectionById(id) != null).isEmpty)
        .length;
    final emptySections = c.allSubCategories
        .where((s) => s.isEnabled && d.inSection(s.id).isEmpty)
        .length;
    final ml = Get.find<MLSettingsController>().mlSettings;
    final practiceOff = ml != null && !ml.practiceEnabled;
    final content = Get.find<ContentController>();

    final items = <Widget>[
      if (missingRecitation > 0)
        _todo(Icons.graphic_eq_rounded, Tone.warning,
            '$missingRecitation live duas have no recitation for an age group that sees them',
            'Their Listen button is greyed out. See which on Audio coverage',
            () => shell.go(PanelTab.audio)),
      if (missingTranslation > 0)
        _todo(Icons.translate_rounded, Tone.neutral,
            '$missingTranslation live duas lack English or Urdu translation audio',
            'Optional: the buttons only appear when a recording exists',
            () => shell.go(PanelTab.audio)),
      if (noSection > 0)
        _todo(Icons.link_off_rounded, Tone.danger,
            '$noSection duas are in no section',
            'Readers cannot reach them', () => shell.go(PanelTab.duas)),
      if (emptySections > 0)
        _todo(Icons.layers_outlined, Tone.warning,
            '$emptySections live sections have no duas',
            'They show up empty in the app', () => shell.go(PanelTab.categories)),
      if (practiceOff)
        _todo(Icons.mic_off_outlined, Tone.neutral,
            'Practice is greyed out in the app',
            'Turn it back on in App controls', () => shell.go(PanelTab.appControls)),
      if (content.publishedAt == null)
        _todo(Icons.sync_problem_rounded, Tone.warning,
            'Phones have never been told about content changes',
            'They only refresh once a day. Send changes from App controls',
            () => shell.go(PanelTab.appControls)),
    ];
    return AdminCard(
      title: 'Needs attention',
      child: items.isEmpty
          ? const Row(children: [
              Icon(Icons.verified_rounded, color: Palette.success),
              SizedBox(width: Space.sm),
              Text('Nothing right now.'),
            ])
          : Column(children: items),
    );
  }

  Widget _todo(IconData icon, Tone tone, String title, String hint, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: tone.color.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: tone.color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(hint, style: AdminText.muted),
      trailing: const Icon(Icons.chevron_right_rounded, color: Palette.textMuted),
    );
  }

  Widget _mostListened(DuaController d, UserController u) {
    final counts = <String, int>{};
    for (final user in u.allUsers) {
      for (final id in user.readDuas) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final readers = u.allUsers.where((x) => x.readDuas.isNotEmpty).length;
    return AdminCard(
      title: 'Most listened',
      subtitle: '$readers signed-in readers have listened to at least one dua to the end.',
      child: top.isEmpty
          ? const Text('No listens recorded yet.', style: AdminText.muted)
          : Column(
              children: [
                for (final e in top.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.byId(e.key)?.title ?? 'A deleted dua',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: StatusChip('${e.value} readers', tone: Tone.brand),
                    onTap: d.byId(e.key) == null
                        ? null
                        : () => pushPage(context, DuaEditor(dua: d.byId(e.key))),
                  ),
              ],
            ),
    );
  }

  Widget _recent(ShellController shell) {
    return GetBuilder<HistoryController>(
      builder: (history) {
        final entries = history.entries.take(8).toList();
        return AdminCard(
          title: 'Recent changes',
          trailing: AdminButton.ghost(
            label: 'All history',
            dense: true,
            onPressed: () => shell.go(PanelTab.history),
          ),
          child: !history.available
              ? const Text(
                  'History will appear once the updated Firestore rules are deployed.',
                  style: AdminText.muted)
              : entries.isEmpty
                  ? const Text('No changes recorded yet.', style: AdminText.muted)
                  : Column(
                      children: [
                        for (final e in entries)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${e.action.verb} ${e.kind.toLowerCase()} ${e.label}',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                if (e.fields.isNotEmpty) describeFields(e.fields),
                                '${e.by} · ${relativeTime(e.at)}',
                              ].join('\n'),
                              style: AdminText.muted,
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}
