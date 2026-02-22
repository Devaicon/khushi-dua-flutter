import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/subCategoryModel.dart';

/// A searchable, **multi‑select** dropdown that works with `SubCategoryModel`.
///
/// *   Tap the field → an overlay pops up.
/// *   Type to filter.
/// *   Tap a row to tick/untick without closing the menu.
/// *   Tap the field again (or outside) to close.
///
/// Usage example:
/// ```dart
/// SearchableMultiSelectDropdown(
///   items: categoryController.allSubCategories,
///   initiallySelected: selectedSubCategories,
///   onChanged: (list) => setState(() => selectedSubCategories = list),
/// )
/// ```
class SearchableMultiSelectDropdown extends StatefulWidget {
  final List<SubCategoryModel> items;
  final List<SubCategoryModel> initiallySelected;
  final ValueChanged<List<SubCategoryModel>> onChanged;

  const SearchableMultiSelectDropdown({
    super.key,
    required this.items,
    required this.initiallySelected,
    required this.onChanged,
  });

  @override
  _SearchableMultiSelectDropdownState createState() =>
      _SearchableMultiSelectDropdownState();
}

class _SearchableMultiSelectDropdownState
    extends State<SearchableMultiSelectDropdown> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  late List<SubCategoryModel> _filtered;
  late List<SubCategoryModel> _selected;

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initiallySelected];
    _filtered = widget.items;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.items;
      } else {
        final matches = widget.items
            .where((e) => e.english.toLowerCase().contains(q))
            .toList();
        final nonMatches = widget.items
            .where((e) => !e.english.toLowerCase().contains(q))
            .toList();
        _filtered = [...matches, ...nonMatches];
      }
    });
  }

  void _toggleMenu() {
    _isMenuOpen ? _hideMenu() : _showMenu();
  }

  void _showMenu() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _focusNode.requestFocus();
    setState(() => _isMenuOpen = true);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtrl.clear();
    _filter();
    _focusNode.unfocus();
    setState(() => _isMenuOpen = false);
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 5),
          showWhenUnlinked: false,
          child: Material(
            color: rBlack,
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 280),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    cursorColor: rGreen,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: rHint.withOpacity(0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final item = _filtered[i];
                        final isSel = _selected.contains(item);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              isSel
                                  ? _selected.remove(item)
                                  : _selected.add(item);
                              widget.onChanged(_selected);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                    isSel
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: isSel ? Colors.green : Colors.grey),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(item.english,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: rHint),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selected.isEmpty
                      ? 'Sub‑categories'
                      : _selected.map((e) => e.english).join(', '),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _selected.isEmpty
                        ? rHint.withOpacity(0.5)
                        : Colors.white,
                  ),
                ),
              ),
              Icon(
                  _isMenuOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: rHint),
            ],
          ),
        ),
      ),
    );
  }
}
