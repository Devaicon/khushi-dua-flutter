import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Saves [content] as a file through the browser's normal download flow.
void downloadTextFile(String filename, String content) {
  final blob = html.Blob([utf8.encode(content)], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  // Revoke later: revoking immediately can cancel the download in some browsers.
  Timer(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}

/// Opens the file picker. Resolves with the chosen CSV, or null if cancelled.
Future<({String name, Uint8List bytes})?> pickCsvFile() {
  final completer = Completer<({String name, Uint8List bytes})?>();
  final input = html.FileUploadInputElement()..accept = '.csv,text/csv';

  void finish(({String name, Uint8List bytes})? result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  input.on['cancel'].listen((_) => finish(null));
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final result = reader.result;
      final bytes = result is ByteBuffer
          ? result.asUint8List()
          : Uint8List.fromList(result as List<int>);
      finish((name: file.name, bytes: bytes));
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
            const FormatException("The file couldn't be read."));
      }
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
