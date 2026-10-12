import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/theme.dart';
import '../controllers/appearanceController.dart';
import '../controllers/authController.dart';
import '../controllers/categoryController.dart';
import '../controllers/contentController.dart';
import '../controllers/duaController.dart';
import '../controllers/historyController.dart';
import '../controllers/notificationController.dart';
import '../controllers/shellController.dart';
import '../controllers/userController.dart';
import '../widgets/ui.dart';
import 'tabs/appControls.dart';
import 'tabs/audioCoverage.dart';
import 'tabs/categories.dart';
import 'tabs/dataTransfer.dart';
import 'tabs/duas.dart';
import 'tabs/history.dart';
import 'tabs/home.dart';
import 'tabs/notifications.dart';
import 'tabs/profile.dart';
import 'tabs/users.dart';

/// The signed-in panel: a sidebar of sections beside the one showing.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Get.find<AuthController>().restoreSession();
    Get.find<CategoryController>().listen();
    Get.find<DuaController>().getAllDuas();
    Get.find<UserController>().getAllUsers();
    Get.find<NotificationController>().getAllNotifications();
    Get.find<HistoryController>().start();
  }

  static Widget _rootOf(PanelTab tab) => switch (tab) {
        PanelTab.overview => const HomeTab(),
        PanelTab.duas => const DuasTab(),
        PanelTab.categories => const CategoriesTab(),
        PanelTab.audio => const AudioCoverageTab(),
        PanelTab.users => const UsersTab(),
        PanelTab.notifications => const NotificationTab(),
        PanelTab.appControls => const AppControlsTab(),
        PanelTab.transfer => const DataTransferTab(),
        PanelTab.history => const HistoryTab(),
        PanelTab.profile => const ProfileTab(),
      };

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShellController>(
      builder: (shell) {
        final compact = MediaQuery.sizeOf(context).width < 1100;
        return Scaffold(
          body: Row(
            children: [
              _Sidebar(shell: shell, compact: compact),
              Expanded(
                child: IndexedStack(
                  index: shell.tab.index,
                  children: [
                    for (final tab in PanelTab.values)
                      // Each section keeps its own page stack.
                      HeroControllerScope.none(
                        child: Navigator(
                          key: shell.navigators[tab],
                          onGenerateRoute: (_) => pageRoute(_rootOf(tab)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.shell, required this.compact});
  final ShellController shell;
  final bool compact;

  static const _groups = <(String, List<PanelTab>)>[
    ('Content', [PanelTab.overview, PanelTab.duas, PanelTab.categories, PanelTab.audio]),
    ('Audience', [PanelTab.users, PanelTab.notifications]),
    ('App', [PanelTab.appControls, PanelTab.transfer, PanelTab.history]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 76 : 248,
      decoration: BoxDecoration(
        color: Palette.card,
        border: Border(right: BorderSide(color: Palette.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brand(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              children: [
                for (final (label, tabs) in _groups) ...[
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Space.md, Space.lg, Space.md, Space.sm),
                      child: Text(label.toUpperCase(), style: AdminText.label),
                    )
                  else
                    const SizedBox(height: Space.md),
                  for (final tab in tabs) _item(tab),
                ],
              ],
            ),
          ),
          const _PublishStatus(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: _AppearanceItem(compact: compact),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
            child: Column(
              children: [
                _item(PanelTab.profile),
                _NavItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  compact: compact,
                  selected: false,
                  danger: true,
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? Space.md : Space.xl, Space.xl, Space.md, Space.md),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: Radii.smAll,
            child: Image.asset('assets/images/logo.png', width: 40, height: 40),
          ),
          if (!compact) ...[
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khushi Dua',
                      style: TextStyle(
                          color: Palette.brand,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('Admin panel', style: AdminText.muted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(PanelTab tab) => _NavItem(
        icon: shell.tab == tab ? tab.selectedIcon : tab.icon,
        label: tab.label,
        compact: compact,
        selected: shell.tab == tab,
        onTap: () => shell.go(tab),
      );

  Future<void> _signOut(BuildContext context) async {
    if (await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in with Google again to use the panel.',
      confirmLabel: 'Sign out',
    )) {
      Get.find<AuthController>().signOut();
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.compact,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Palette.danger
        : (selected ? Palette.brand : Palette.textMuted);
    final tile = Material(
      color: selected ? Palette.brandSoft : Colors.transparent,
      borderRadius: Radii.smAll,
      child: InkWell(
        borderRadius: Radii.smAll,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : Space.md, vertical: Space.md - 2),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 21, color: color),
              if (!compact) ...[
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: danger
                          ? Palette.danger
                          : (selected ? Palette.brand : Palette.text),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: compact ? Tooltip(message: label, child: tile) : tile,
    );
  }
}

/// Whether phones have been told about the latest content changes.
class _PublishStatus extends StatelessWidget {
  const _PublishStatus();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ContentController>(
      builder: (content) {
        final busy = content.pending || content.publishing;
        final compact = MediaQuery.sizeOf(context).width < 1100;
        final label = busy
            ? 'Sending changes to phones…'
            : (content.publishedAt == null
                ? 'Phones refresh content daily'
                : 'Phones told ${relativeTime(content.publishedAt!)}');
        final icon = Icon(
          busy ? Icons.sync_rounded : Icons.cloud_done_outlined,
          size: 18,
          color: busy ? Palette.warning : Palette.success,
        );
        return Tooltip(
          message: 'When content changes, phones download it again on their '
              'next launch. Version ${content.version ?? '–'}.',
          child: Container(
            margin: const EdgeInsets.all(Space.md),
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: Palette.raised,
              borderRadius: Radii.smAll,
            ),
            child: compact
                ? icon
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                color: Palette.text, fontSize: 12)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Light, dark or system, as in the app's Settings.
class _AppearanceItem extends StatelessWidget {
  const _AppearanceItem({required this.compact});
  final bool compact;

  static IconData _icon(String mode) => switch (mode) {
        'light' => Icons.light_mode_outlined,
        'dark' => Icons.dark_mode_outlined,
        _ => Icons.brightness_auto_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppearanceController>(
      builder: (appearance) => PopupMenuButton<String>(
        tooltip: 'Appearance',
        position: PopupMenuPosition.under,
        onSelected: appearance.setMode,
        itemBuilder: (_) => [
          for (final MapEntry(key: mode, value: label)
              in AppearanceController.modes.entries)
            PopupMenuItem(
              value: mode,
              child: Row(
                children: [
                  Icon(_icon(mode), size: 20, color: Palette.text),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(label)),
                  if (mode == appearance.mode)
                    Icon(Icons.check_rounded, size: 18, color: Palette.brand),
                ],
              ),
            ),
        ],
        child: IgnorePointer(
          child: _NavItem(
            icon: _icon(appearance.mode),
            label:
                'Appearance: ${AppearanceController.modes[appearance.mode]}',
            compact: compact,
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
