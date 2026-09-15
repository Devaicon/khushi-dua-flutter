import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../csv/csvCodec.dart';
import '../../csv/csvSchema.dart';
import '../../csv/importPlanner.dart';
import '../../helpers/webFiles.dart';
import '../../services/csvTransferService.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/topBar.dart';

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
            backgroundColor: rBg,
            title: const Text("Import stopped",
                style: TextStyle(color: rWhite, fontWeight: FontWeight.bold)),
            content: Text(e.describe(), style: const TextStyle(color: rWhite)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: rGreen)),
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
      backgroundColor: rBlack,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopBar(title: "Import / Export"),
            const SizedBox(height: 12),
            const Text(
              "Exports open in Excel with every language intact. To import, "
              "edit an export and save it as \"CSV UTF-8\". You'll review "
              "every change before anything is saved.",
              style: TextStyle(color: rHint),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: schemas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _datasetCard(schemas[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datasetCard(CsvSchema schema) {
    final busy = _busy == schema.dataset;
    final anyBusy = _busy != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: rBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schema.label,
                    style: const TextStyle(
                        color: rWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(schema.description,
                    style: const TextStyle(color: rHint, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (busy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: rGreen),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: anyBusy ? null : () => _export(schema),
              icon: const Icon(Icons.download_rounded, color: rGreen),
              label: const Text("Export", style: TextStyle(color: rWhite)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: rGreen)),
            ),
            if (schema.importable) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: anyBusy ? null : () => _import(schema),
                icon: const Icon(Icons.upload_rounded, color: rYellow),
                label: const Text("Import", style: TextStyle(color: rWhite)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: rYellow)),
              ),
            ],
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
      backgroundColor: rBg,
      title: Text("Review import: $fileName",
          style: const TextStyle(color: rWhite, fontWeight: FontWeight.bold)),
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
                _chip("${plan.count(RowStatus.create)} new", rGreen),
                _chip("${plan.count(RowStatus.update)} changed", rYellow),
                _chip("${plan.count(RowStatus.unchanged)} unchanged", rHint),
                _chip("${plan.count(RowStatus.invalid)} with errors", rRed),
              ],
            ),
            if (plan.schema.dataset == CsvDataset.notifications) ...[
              const SizedBox(height: 12),
              const Text(
                "Imported notifications appear in the app's notification list. They are not sent to phones.",
                style: TextStyle(color: rYellow),
              ),
            ],
            const SizedBox(height: 16),
            if (plan.fileErrors.isNotEmpty)
              ...plan.fileErrors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("• $e", style: const TextStyle(color: rRed)),
                  ))
            else if (visibleRows.isEmpty)
              const Text("Every row matches the database. Nothing to import.",
                  style: TextStyle(color: rHint))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: visibleRows.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: rHint.withOpacity(0.2)),
                  itemBuilder: (context, index) => _rowTile(visibleRows[index]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: rHint)),
        ),
        ElevatedButton(
          onPressed: plan.canApply ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: rGreen, foregroundColor: rWhite),
          child: Text(plan.canApply
              ? "Back up & apply ${plan.writeCount} changes"
              : "Fix the errors to import"),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      );

  Widget _rowTile(PlannedRow row) {
    final (label, color) = switch (row.status) {
      RowStatus.create => ("New", rGreen),
      RowStatus.update => ("Changed", rYellow),
      RowStatus.invalid => ("Error", rRed),
      RowStatus.unchanged => ("Unchanged", rHint),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Row ${row.rowNumber}",
                style: const TextStyle(
                    color: rWhite, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.id.isEmpty ? "(new id)" : row.id,
                  style: const TextStyle(
                      color: rHint, fontFamily: 'monospace', fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            _chip(label, color),
          ],
        ),
        if (row.status == RowStatus.update)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text("Changes: ${row.changes.keys.join(', ')}",
                style: const TextStyle(color: rWhite, fontSize: 13)),
          ),
        for (final error in row.errors)
          Text("• $error", style: const TextStyle(color: rRed, fontSize: 13)),
        for (final warning in row.warnings)
          Text("• $warning",
              style: const TextStyle(color: rYellow, fontSize: 13)),
      ],
    );
  }
}
