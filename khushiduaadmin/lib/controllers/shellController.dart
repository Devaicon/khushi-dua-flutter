import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The panel's sections, in sidebar order.
enum PanelTab {
  overview('Overview', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  duas('Duas', Icons.menu_book_outlined, Icons.menu_book_rounded),
  categories('Categories', Icons.folder_outlined, Icons.folder_rounded),
  audio('Audio coverage', Icons.graphic_eq_outlined, Icons.graphic_eq_rounded),
  users('Users', Icons.people_outline_rounded, Icons.people_rounded),
  notifications('Notifications', Icons.notifications_none_rounded, Icons.notifications_rounded),
  appControls('App controls', Icons.tune_outlined, Icons.tune_rounded),
  transfer('Import / Export', Icons.swap_vert_outlined, Icons.swap_vert_rounded),
  history('History', Icons.history_outlined, Icons.history_rounded),
  profile('Profile & admins', Icons.badge_outlined, Icons.badge_rounded);

  const PanelTab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Which section is showing, and a navigator per section so a pushed page
/// (an editor, a section's duas) keeps the sidebar beside it.
class ShellController extends GetxController {
  PanelTab _tab = PanelTab.overview;
  PanelTab get tab => _tab;

  final Map<PanelTab, GlobalKey<NavigatorState>> navigators = {
    for (final t in PanelTab.values) t: GlobalKey<NavigatorState>(),
  };

  /// Shows [tab]. Choosing the section already showing returns it to its
  /// first page.
  void go(PanelTab tab) {
    if (tab == _tab) {
      navigators[tab]!.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    _tab = tab;
    update();
  }

  /// Shows [tab] and opens [page] on top of it.
  void open(PanelTab tab, Widget page) {
    go(tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigators[tab]!.currentState?.push(pageRoute(page));
    });
  }
}

/// A quick fade, for pages inside a section.
Route<T> pageRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

/// Opens [page] inside the current section.
Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(pageRoute(page));
