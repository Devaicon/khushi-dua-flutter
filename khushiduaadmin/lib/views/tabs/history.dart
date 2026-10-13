import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/historyController.dart';
import '../../helpers/auditDiff.dart';
import '../../models/auditEntry.dart';
import '../../search/adminSearch.dart';
import '../../services/auditService.dart';
import '../../widgets/adminSearchField.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';

/// Every change made from the panel: who, what and when, with undo.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _query = '';
  String? _kind;
  final Set<String> _undoing = {};

  Future<void> _undo(AuditEntry e) async {
    final what = e.action == AuditAction.create
        ? 'delete ${e.kind.toLowerCase()} "${e.label}" again'
        : e.action == AuditAction.reorder
            ? 'put the ${e.label} back in their earlier order'
            : 'put ${e.kind.toLowerCase()} "${e.label}" back as it was before '
                'this change. Edits made to it since will be lost';
    if (!await confirmAction(context,
        title: 'Undo this change?',
        message: 'This will $what.',
        confirmLabel: 'Undo')) {
      return;
    }
    setState(() => _undoing.add(e.id));
    try {
      await AuditService.undo(e);
      CustomSnackbar.show('Change undone', '${e.kind}: ${e.label}');
    } catch (err) {
      CustomSnackbar.show("Couldn't undo", '$err', isSuccess: false);
    } finally {
      if (mounted) setState(() => _undoing.remove(e.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<HistoryController>(
        builder: (history) {
          final kinds = {for (final e in history.entries) e.kind}.toList()..sort();
          final visible = filterBySearch(
            [for (final e in history.entries) if (_kind == null || e.kind == _kind) e],
            _query,
            (e) => [e.label, e.by, e.kind, ...e.fields.map(fieldLabel)],
          );
          return AdminPage(
            scroll: false,
            title: 'History',
            subtitle: 'The last ${HistoryController.limit} changes made in this '
                'panel. Undo puts a document back as it was.',
            child: !history.available
                ? const AdminCard(
                    child: EmptyState(
                      icon: Icons.lock_clock_outlined,
                      title: 'History needs the updated Firestore rules',
                      message: 'Changes are saved as usual, but the history of '
                          'them can only be kept once the rules allowing the '
                          'AuditLog collection are deployed.',
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AdminSearchField(
                              hint: 'Search by name, admin or field',
                              matchCount: visible.length,
                              totalCount: history.entries.length,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          const SizedBox(width: Space.md),
                          Wrap(
                            spacing: Space.xs,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _kind == null,
                                onSelected: (_) => setState(() => _kind = null),
                              ),
                              for (final k in kinds)
                                ChoiceChip(
                                  label: Text(k),
                                  selected: _kind == k,
                                  onSelected: (_) => setState(() => _kind = k),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.lg),
                      Expanded(
                        child: AdminCard(
                          padding: EdgeInsets.zero,
                          // The list needs a bounded height to scroll in;
                          // without it, it draws nothing.
                          expand: true,
                          child: visible.isEmpty
                              ? SingleChildScrollView(
                                  child: EmptyState(
                                  icon: Icons.history_rounded,
                                  title: history.loaded
                                      ? 'No changes recorded yet'
                                      : 'Loading history…',
                                  message: history.loaded
                                      ? 'Edits made from now on will appear here.'
                                      : null,
                                ),
                                )
                              : ListView.separated(
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) => _entry(visible[i]),
                                ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _entry(AuditEntry e) {
    final (icon, tone) = switch (e.action) {
      AuditAction.create => (Icons.add_circle_outline_rounded, Tone.success),
      AuditAction.update => (Icons.edit_outlined, Tone.info),
      AuditAction.delete => (Icons.delete_outline_rounded, Tone.danger),
      AuditAction.reorder => (Icons.swap_vert_rounded, Tone.brand),
      AuditAction.restore => (Icons.undo_rounded, Tone.warning),
      AuditAction.other => (Icons.change_circle_outlined, Tone.neutral),
    };
    final canUndo = e.undoable &&
        !e.undone &&
        e.action != AuditAction.restore &&
        e.action != AuditAction.other;
    final detail = switch (e.action) {
      AuditAction.update => describeFields(e.fields),
      AuditAction.reorder => '${e.after?.length ?? 0} moved',
      _ => null,
    };

    return ExpansionTile(
      shape: const Border(),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: tone.color.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: tone.color),
      ),
      title: Text.rich(
        TextSpan(children: [
          TextSpan(text: '${e.action.verb} '),
          TextSpan(text: '${e.kind.toLowerCase()} '),
          TextSpan(
              text: e.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (detail != null)
            TextSpan(text: ' · $detail', style: AdminText.muted),
        ]),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${e.by.isEmpty ? 'Unknown admin' : e.by} · ${relativeTime(e.at)}',
        style: AdminText.muted,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (e.undone)
            const StatusChip('Undone', tone: Tone.neutral)
          else if (canUndo)
            AdminButton.secondary(
              label: 'Undo',
              icon: Icons.undo_rounded,
              dense: true,
              busy: _undoing.contains(e.id),
              onPressed: () => _undo(e),
            ),
          const SizedBox(width: Space.sm),
          Icon(Icons.expand_more_rounded, color: Palette.textMuted),
        ],
      ),
      childrenPadding:
          const EdgeInsets.fromLTRB(72, 0, Space.xl, Space.lg),
      children: [_diff(e)],
    );
  }

  Widget _diff(AuditEntry e) {
    if (e.action == AuditAction.reorder) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${e.after?.length ?? 0} items changed position.',
          style: AdminText.muted,
        ),
      );
    }
    final fields = e.action == AuditAction.update
        ? e.fields
        : changedFields(e.before, e.after);
    if (fields.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('No field details recorded.', style: AdminText.muted),
      );
    }
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(150),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(32),
        3: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final f in fields)
          TableRow(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(fieldLabel(f),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            _value(e.before?[f], Palette.danger),
            Icon(Icons.arrow_forward_rounded, size: 14, color: Palette.textMuted),
            _value(e.after?[f], Palette.success),
          ]),
      ],
    );
  }

  Widget _value(Object? v, Color color) {
    final text = switch (v) {
      null => '—',
      String s when s.isEmpty => '—',
      String s when s.startsWith('https://firebasestorage') => 'a recording',
      Timestamp t => relativeTime(t.toDate()),
      List l => l.isEmpty ? '—' : '${l.length} items',
      bool b => b ? 'Yes' : 'No',
      _ => '$v',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: text == '—' ? Palette.textMuted : color, fontSize: 13),
      ),
    );
  }
}
