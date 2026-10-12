/// The building blocks every admin screen is made of. Screens compose these
/// rather than styling containers themselves, so the panel reads as one
/// product.
library;

import 'package:flutter/material.dart';

import '../constants/languages.dart';
import '../constants/theme.dart';

/// A screen: title, optional subtitle and actions, then the content.
///
/// [scroll] wraps the content in a scroll view; pass false when the content
/// has its own (a long list), and it will be given the remaining height.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.scroll = true,
    this.leading,
    this.maxWidth = 1280,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool scroll;
  final Widget? leading;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final header = PageHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      leading: leading,
    );
    final body = scroll
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Space.xl, 0, Space.xl, Space.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, const SizedBox(height: Space.xl), child],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: Space.xl),
                Expanded(child: child),
              ],
            ),
          );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: Space.md,
        spacing: Space.lg,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: Space.sm)],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Palette.brand,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                            color: Palette.textMuted, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: actions),
        ],
      ),
    );
  }
}

/// A back arrow for pages pushed on top of a tab.
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: Palette.card,
        side: BorderSide(color: Palette.line),
      ),
      icon: Icon(Icons.arrow_back_rounded, color: Palette.brand),
    );
  }
}

/// The one surface: white, rounded, softly shadowed.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(Space.xl),
    this.onTap,
    this.color,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Palette.card;
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: AdminText.cardTitle),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Space.xs),
                          child: Text(subtitle!, style: AdminText.muted),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: Space.lg),
          ],
          child,
        ],
      ),
    );
    return Material(
      color: color,
      borderRadius: Radii.cardAll,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: Radii.cardAll,
          boxShadow: Elevation.card,
          color: color,
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

abstract final class AdminText {
  static TextStyle get cardTitle => TextStyle(
    color: Palette.text,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get muted => TextStyle(color: Palette.textMuted, fontSize: 13, height: 1.4);
  static TextStyle get label => TextStyle(
    color: Palette.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
  static TextStyle get body => TextStyle(color: Palette.text, fontSize: 14);
  static TextStyle get mono => TextStyle(
    color: Palette.textMuted,
    fontFamily: 'monospace',
    fontSize: 12,
  );
}

/// A small uppercase label above a group of fields, as in the app.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Row(
          children: [
            Expanded(child: Text(text.toUpperCase(), style: AdminText.label)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

enum ButtonKind { primary, secondary, danger, ghost }

class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = ButtonKind.primary,
    this.busy = false,
    this.dense = false,
    this.tooltip,
  });

  const AdminButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.dense = false,
    this.tooltip,
  }) : kind = ButtonKind.secondary;

  const AdminButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.dense = false,
    this.tooltip,
  }) : kind = ButtonKind.danger;

  const AdminButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.dense = false,
    this.tooltip,
  }) : kind = ButtonKind.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonKind kind;
  final bool busy;
  final bool dense;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      ButtonKind.primary => (Palette.brandFill, Colors.white, Colors.transparent),
      ButtonKind.secondary => (Palette.card, Palette.brand, Palette.line),
      ButtonKind.danger => (Palette.danger, Colors.white, Colors.transparent),
      ButtonKind.ghost => (Colors.transparent, Palette.brand, Colors.transparent),
    };
    final enabled = onPressed != null && !busy;
    final iconWidget = busy
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : (icon == null ? null : Icon(icon, size: 18, color: fg));

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: kind == ButtonKind.ghost
            ? Colors.transparent
            : bg.withValues(alpha: 0.45),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? Space.md : Space.lg + 2,
          vertical: dense ? Space.sm : Space.md + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.smAll,
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: dense ? 13 : 14,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null) ...[iconWidget, const SizedBox(width: Space.sm)],
          Text(label),
        ],
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

enum Tone { neutral, brand, success, warning, danger, info }

extension ToneColor on Tone {
  Color get color => switch (this) {
        Tone.neutral => Palette.textMuted,
        Tone.brand => Palette.brand,
        Tone.success => Palette.success,
        Tone.warning => Palette.warning,
        Tone.danger => Palette.danger,
        Tone.info => Palette.info,
      };
}

/// A pill with a short status: "Live", "Hidden", "Missing audio".
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = Tone.neutral, this.icon});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = tone.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A headline number with a label, for the tops of screens.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Palette.brand;
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.lg + 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: Radii.smAll,
            ),
            child: Icon(icon, color: inkOf(color)),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: AdminText.muted),
                if (caption != null)
                  Text(
                    caption!,
                    style: TextStyle(
                      color: inkOf(color),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays children out in equal columns that wrap on narrow screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.spacing = Space.lg,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth)
            .floor()
            .clamp(1, children.isEmpty ? 1 : children.length);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Palette.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Palette.brand, size: 30),
          ),
          const SizedBox(height: Space.lg),
          Text(title, style: AdminText.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Space.xs),
            Text(message!, style: AdminText.muted, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: Space.lg), action!],
        ],
      ),
    );
  }
}

/// A column of a list table: a fixed [width], or a share of what is left.
class TableCol {
  const TableCol(this.label, {this.flex = 1, this.width});
  final String label;
  final int flex;
  final double? width;
}

/// A list laid out as a table: a header, then [rowCount] rows from
/// [rowBuilder], each a list of cells matching [columns].
///
/// Scrolls itself (lazily) unless [shrinkWrap].
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.rowBuilder,
    this.onRowTap,
    this.shrinkWrap = false,
    this.empty,
  });

  final List<TableCol> columns;
  final int rowCount;
  final List<Widget> Function(int index) rowBuilder;
  final void Function(int index)? onRowTap;
  final bool shrinkWrap;
  final Widget? empty;

  static Widget cells(List<TableCol> columns, List<Widget> cells) {
    return Row(
      children: [
        for (var i = 0; i < columns.length; i++)
          if (columns[i].width != null)
            SizedBox(width: columns[i].width, child: cells[i])
          else
            Expanded(flex: columns[i].flex, child: cells[i]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      decoration: BoxDecoration(
        color: Palette.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.card)),
      ),
      child: cells(columns, [
        for (final c in columns) Text(c.label.toUpperCase(), style: AdminText.label),
      ]),
    );

    Widget row(int index) {
      final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
        child: cells(columns, rowBuilder(index)),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index > 0) const Divider(height: 1),
          onRowTap == null
              ? content
              : InkWell(
                  onTap: () => onRowTap!(index),
                  hoverColor: Palette.raised,
                  child: content,
                ),
        ],
      );
    }

    final Widget list;
    if (rowCount == 0) {
      list = empty ?? const SizedBox(height: Space.xl);
    } else if (shrinkWrap) {
      list = Column(children: [for (var i = 0; i < rowCount; i++) row(i)]);
    } else {
      list = ListView.builder(itemCount: rowCount, itemBuilder: (_, i) => row(i));
    }

    return Material(
      color: Palette.card,
      borderRadius: Radii.cardAll,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(borderRadius: Radii.cardAll, boxShadow: Elevation.card),
        child: Column(
          mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          children: [
            header,
            if (shrinkWrap || rowCount == 0) list else Expanded(child: list),
          ],
        ),
      ),
    );
  }
}

/// Three dots, one per age group, filled where the item is shown.
class AgeDots extends StatelessWidget {
  const AgeDots({super.key, required this.shownTo});
  final bool Function(AgeGroup group) shownTo;

  static Color colorOf(AgeGroup group) => switch (group) {
        AgeGroup.littleKids => Palette.littleKids,
        AgeGroup.olderKids => Palette.olderKids,
        AgeGroup.grownUps => Palette.grownUps,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in AgeGroup.values)
          Tooltip(
            message: '${group.label}: ${shownTo(group) ? 'shown' : 'hidden'}',
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: shownTo(group) ? colorOf(group) : Colors.transparent,
                border: Border.all(
                  color: shownTo(group) ? inkOf(colorOf(group)) : Palette.line,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A slim bar showing [value] (0–1).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color});
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Palette.brand;
    return ClipRRect(
      borderRadius: Radii.pillAll,
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: color,
        backgroundColor: color.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Asks before doing something. Resolves true only on confirmation.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(message, style: const TextStyle(height: 1.5)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      actions: [
        AdminButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AdminButton(
          label: confirmLabel,
          kind: danger ? ButtonKind.danger : ButtonKind.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A translucent cover with a spinner, over a screen that is saving.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Palette.page.withValues(alpha: 0.7),
        child: Center(
          child: AdminCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: Space.md),
                Text(message ?? 'Saving…', style: AdminText.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "3 minutes ago", "Yesterday", "12 Oct".
String relativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final sameYear = time.year == (now ?? DateTime.now()).year;
  return '${time.day} ${months[time.month - 1]}${sameYear ? '' : ' ${time.year}'}';
}

String formatCount(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
