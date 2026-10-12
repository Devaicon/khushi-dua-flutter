import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/contentController.dart';
import '../../csv/csvCodec.dart';
import '../../csv/csvSchema.dart';
import '../../csv/importPlanner.dart';
import '../../helpers/webFiles.dart';
import '../../services/csvTransferService.dart';
import '../../models/auditEntry.dart';
import '../../services/auditService.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';

class DataTransferTab extends StatefulWidget {
  const DataTransferTab({super.key});

  @override
  State<DataTransferTab> createState() => _DataTransferTabState();
}

class _DataTransferTabState extends State<DataTransferTab> {
  final CsvTransferService _service = CsvTransferService();
  CsvDataset? _busy;

  Future<void> _export(CsvSchema schema) async {
    setState(() => _busy = schema.dataset);
    try {
      final count = await _service.export(schema);
      CustomSnackbar.show(
          "Success", "Exported $count ${schema.label.toLowerCase()}.");
    } catch (e) {
      CustomSnackbar.show("Error", "Export failed: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _import(CsvSchema schema) async {
    final picked = await pickCsvFile();
    if (picked == null || !mounted) return;

    setState(() => _busy = schema.dataset);
    try {
      final plan = await _service.plan(schema, picked.bytes);
      if (!mounted) return;
      setState(() => _busy = null);

      final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                ImportPreviewDialog(plan: plan, fileName: picked.name),
          ) ??
          false;
      if (!confirmed || !mounted) return;

      setState(() => _busy = schema.dataset);
      final written = await _service.apply(plan);
      const content = {
        CsvDataset.duas,
        CsvDataset.categories,
        CsvDataset.subCategories,
      };
      if (content.contains(schema.dataset)) {
        Get.find<ContentController>().contentChanged();
      }
      await AuditService.record(
        action: AuditAction.other,
        collection: schema.label,
        docId: '',
        label: '$written ${schema.label.toLowerCase()} from ${picked.name}',
        undoable: false,
      );
      CustomSnackbar.show(
        "Success",
        "Imported $written changes. A backup of the previous "
            "${schema.label.toLowerCase()} was downloaded first.",
      );
    } on CsvFormatException catch (e) {
      CustomSnackbar.show("Error", e.message, isSuccess: false);
    } on ImportApplyException catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Import stopped"),
            content: Text(e.describe()),
            actions: [
              AdminButton(
                label: "OK",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      CustomSnackbar.show("Error", "Import failed: $e", isSuccess: false);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemas = kCsvSchemas.values.toList();

    return Scaffold(
      body: AdminPage(
        title: 'Import / Export',
        subtitle: 'Exports open in Excel with every language intact. To '
            'import, edit an export and save it as "CSV UTF-8". You review '
            'every change, and a backup downloads, before anything is saved.',
        maxWidth: 960,
        child: Column(
          children: [
            for (final schema in schemas) ...[
              _datasetCard(schema),
              const SizedBox(height: Space.md),
            ],
          ],
        ),
      ),
    );
  }

  Widget _datasetCard(CsvSchema schema) {
    final busy = _busy == schema.dataset;
    final anyBusy = _busy != null;

    return AdminCard(
      padding: const EdgeInsets.all(Space.lg + 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schema.label, style: AdminText.cardTitle),
                const SizedBox(height: Space.xs),
                Text(schema.description, style: AdminText.muted),
              ],
            ),
          ),
          const SizedBox(width: Space.lg),
          AdminButton.secondary(
            label: 'Export',
            icon: Icons.download_rounded,
            busy: busy,
            onPressed: anyBusy ? null : () => _export(schema),
          ),
          if (schema.importable) ...[
            const SizedBox(width: Space.sm),
            AdminButton.secondary(
              label: 'Import',
              icon: Icons.upload_rounded,
              onPressed: anyBusy ? null : () => _import(schema),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows what an import will do and asks for confirmation. Pops `true` to
/// apply, `false` to cancel.
class ImportPreviewDialog extends StatelessWidget {
  const ImportPreviewDialog({
    super.key,
    required this.plan,
    required this.fileName,
  });

  final ImportPlan plan;
  final String fileName;

  static const _statusOrder = {
    RowStatus.invalid: 0,
    RowStatus.create: 1,
    RowStatus.update: 2,
    RowStatus.unchanged: 3,
  };

  @override
  Widget build(BuildContext context) {
    final visibleRows = plan.rows
        .where((r) => r.status != RowStatus.unchanged)
        .toList()
      ..sort((a, b) {
        final byStatus =
            _statusOrder[a.status]!.compareTo(_statusOrder[b.status]!);
        return byStatus != 0 ? byStatus : a.rowNumber.compareTo(b.rowNumber);
      });

    return AlertDialog(
      title: Text("Review import: $fileName"),
      content: SizedBox(
        width: 900,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip("${plan.count(RowStatus.create)} new", tone: Tone.success),
                StatusChip("${plan.count(RowStatus.update)} changed", tone: Tone.warning),
                StatusChip("${plan.count(RowStatus.unchanged)} unchanged"),
                StatusChip("${plan.count(RowStatus.invalid)} with errors", tone: Tone.danger),
              ],
            ),
            if (plan.schema.dataset == CsvDataset.notifications) ...[
              const SizedBox(height: 12),
              const Text(
                "Imported notifications appear in the app's notification list. They are not sent to phones.",
                style: TextStyle(color: Palette.warning),
              ),
            ],
            const SizedBox(height: 16),
            if (plan.fileErrors.isNotEmpty)
              ...plan.fileErrors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("• $e", style: const TextStyle(color: Palette.danger)),
                  ))
            else if (visibleRows.isEmpty)
              const Text("Every row matches the database. Nothing to import.",
                  style: AdminText.muted)
            else
              Expanded(
                child: ListView.separated(
                  itemCount: visibleRows.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) => _rowTile(visibleRows[index]),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
      actions: [
        AdminButton.ghost(
          label: "Cancel",
          onPressed: () => Navigator.pop(context, false),
        ),
        AdminButton(
          label: plan.canApply
              ? "Back up & apply ${plan.writeCount} changes"
              : "Fix the errors to import",
          onPressed: plan.canApply ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }

  Widget _rowTile(PlannedRow row) {
    final (label, tone) = switch (row.status) {
      RowStatus.create => ("New", Tone.success),
      RowStatus.update => ("Changed", Tone.warning),
      RowStatus.invalid => ("Error", Tone.danger),
      RowStatus.unchanged => ("Unchanged", Tone.neutral),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Row ${row.rowNumber}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.id.isEmpty ? "(new id)" : row.id,
                  style: AdminText.mono,
                  overflow: TextOverflow.ellipsis),
            ),
            StatusChip(label, tone: tone),
          ],
        ),
        if (row.status == RowStatus.update)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text("Changes: ${row.changes.keys.join(', ')}",
                style: const TextStyle(fontSize: 13)),
          ),
        for (final error in row.errors)
          Text("• $error", style: const TextStyle(color: Palette.danger, fontSize: 13)),
        for (final warning in row.warnings)
          Text("• $warning",
              style: const TextStyle(color: Palette.warning, fontSize: 13)),
      ],
    );
  }
}
