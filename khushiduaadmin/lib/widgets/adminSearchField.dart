import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/theme.dart';
import 'ui.dart';

/// Search box for the admin lists. Reports every keystroke through
/// [onChanged]; Escape or the clear button empties it.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.matchCount,
    required this.totalCount,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  /// Shown as "matchCount of totalCount" while there is a query.
  final int matchCount;
  final int totalCount;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded,
              color: Palette.textMuted, size: 20),
          suffixIcon: hasText
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.matchCount} of ${widget.totalCount}",
                      style: AdminText.muted,
                    ),
                    IconButton(
                      tooltip: "Clear search (Esc)",
                      icon: const Icon(Icons.close_rounded,
                          color: Palette.textMuted, size: 18),
                      onPressed: _clear,
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

/// Shown above a list's rows while searching: either that nothing matched,
/// or that drag-to-reorder is off until the search is cleared.
class SearchResultsNote extends StatelessWidget {
  const SearchResultsNote({
    super.key,
    required this.query,
    required this.matchCount,
    required this.itemLabel,
    this.reorderPaused = false,
  });

  final String query;
  final int matchCount;

  /// Plural noun, e.g. "duas".
  final String itemLabel;
  final bool reorderPaused;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (matchCount == 0) {
      text = "No $itemLabel match \"${query.trim()}\".";
    } else if (reorderPaused) {
      text = "Clear the search to drag $itemLabel into a new order.";
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.lg, vertical: Space.md),
      child: Text(text, style: AdminText.muted),
    );
  }
}
