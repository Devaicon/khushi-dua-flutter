import 'package:flutter/material.dart';

import '../constants/theme.dart';
import 'ui.dart';

/// A card of rows that can be dragged into a new order by their handles.
///
/// [onReorder] gets the list in its new order; the rows move at once and
/// the caller saves. Dragging is off while [reorderable] is false (during a
/// search, say) and the handles are hidden.
class ReorderList<T> extends StatelessWidget {
  const ReorderList({
    super.key,
    required this.items,
    required this.idOf,
    required this.rowBuilder,
    required this.onReorder,
    this.onTap,
    this.reorderable = true,
    this.empty,
  });

  final List<T> items;
  final String Function(T item) idOf;
  final Widget Function(T item) rowBuilder;
  final void Function(List<T> reordered) onReorder;
  final void Function(T item)? onTap;
  final bool reorderable;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AdminCard(padding: EdgeInsets.zero, child: empty ?? const SizedBox());
    }
    return AdminCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: items.length,
        proxyDecorator: (child, _, __) => Material(
          elevation: 6,
          color: Palette.card,
          borderRadius: Radii.smAll,
          child: child,
        ),
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final next = [...items];
          next.insert(newIndex, next.removeAt(oldIndex));
          onReorder(next);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return Column(
            key: ValueKey(idOf(item)),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) const Divider(height: 1, indent: Space.lg, endIndent: Space.lg),
              InkWell(
                onTap: onTap == null ? null : () => onTap!(item),
                hoverColor: Palette.raised,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.md, vertical: Space.sm),
                  child: Row(
                    children: [
                      if (reorderable)
                        ReorderableDragStartListener(
                          index: index,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: const EdgeInsets.all(Space.sm),
                              child: Icon(Icons.drag_indicator_rounded,
                                  color: Palette.textMuted),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: Space.sm),
                      SizedBox(
                        width: 32,
                        child: Text('${index + 1}',
                            textAlign: TextAlign.center,
                            style: AdminText.muted),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(child: rowBuilder(item)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A square thumbnail of a category logo or section illustration.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.url, {super.key, this.size = 44, this.icon = Icons.image_outlined});
  final String url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Palette.raised,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(icon, color: Palette.textMuted, size: size * 0.5)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined,
                  color: Palette.textMuted, size: size * 0.5),
            ),
    );
  }
}
