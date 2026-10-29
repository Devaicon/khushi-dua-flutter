import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads files picked in the browser to Firebase Storage.
abstract final class StorageService {
  /// Uploads [file] to [path] and returns its download URL.
  ///
  /// Throws when the upload fails. (The old helper returned null, which every
  /// caller force-unwrapped, so a failed upload crashed the save midway.)
  static Future<String> upload(
    html.File file,
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final contentType = file.type.isNotEmpty
        ? file.type
        : (file.name.toLowerCase().endsWith('.mp3') ? 'audio/mpeg' : null);
    final task = ref.putBlob(
      file,
      contentType == null ? null : SettableMetadata(contentType: contentType),
    );
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
      });
    }
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }
}

/// Whether [file] is an SVG. Browsers usually report `image/svg+xml`, but
/// some leave the type empty, so the name is checked too.
bool isSvgFile(html.File file) =>
    file.type == 'image/svg+xml' || file.name.toLowerCase().endsWith('.svg');

/// Opens the browser's file picker. Resolves with the files chosen, or an
/// empty list when cancelled.
Future<List<html.File>> pickFiles({
  required String accept,
  bool multiple = false,
}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = multiple;
  input.click();
  await Future.any([input.onChange.first, input.on['cancel'].first]);
  return input.files ?? const [];
}
