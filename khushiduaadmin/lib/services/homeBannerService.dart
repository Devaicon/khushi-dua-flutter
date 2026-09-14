import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/homeBannerController.dart';
import '../models/homeBannerModel.dart';
import '../widgets/customSnackbar.dart';

/// Reads and writes `SystemConfiguration/HomeBanner`.
///
/// The app listens to the same document, so a save here reaches every running
/// app immediately — no release required.
class HomeBannerService {
  HomeBannerController get _controller => Get.find<HomeBannerController>();

  Future<void> getBanner() async {
    try {
      _controller.setLoading(true);
      final snapshot = await sysConfigRef.doc(HomeBannerModel.docId).get();

      _controller.setBanner(
        snapshot.exists && snapshot.data() != null
            ? HomeBannerModel.fromMap(snapshot.data()!)
            : HomeBannerModel.empty(),
      );
      _controller.setLoading(false);
    } catch (e) {
      debugPrint("Error getting home banner: $e");
      _controller.setLoading(false);
      CustomSnackbar.show(
        "Error",
        "Failed to load the home banner",
        isSuccess: false,
      );
    }
  }

  Future<bool> saveBanner(
    HomeBannerModel banner, {
    dynamic imageFile,
  }) async {
    try {
      _controller.setLoading(true);

      if (imageFile is html.File) {
        final url = await _uploadImage(imageFile);
        if (url == null) {
          _controller.setLoading(false);
          CustomSnackbar.show(
            "Error",
            "Failed to upload the banner image",
            isSuccess: false,
          );
          return false;
        }
        banner.imageUrl = url;
      }

      banner.updatedAt = DateTime.now();
      // merge so a future field added by another writer is not wiped out.
      await sysConfigRef
          .doc(HomeBannerModel.docId)
          .set(banner.toMap(), SetOptions(merge: true));

      _controller.setBanner(banner);
      _controller.setLoading(false);
      CustomSnackbar.show("Success", "Home banner updated");
      return true;
    } catch (e) {
      debugPrint("Error saving home banner: $e");
      _controller.setLoading(false);
      CustomSnackbar.show(
        "Error",
        "Failed to save the home banner",
        isSuccess: false,
      );
      return false;
    }
  }

  Future<String?> _uploadImage(html.File file) async {
    try {
      // Timestamped so a replacement image is not served from a cached URL.
      final path =
          'homeBanner/banner_${DateTime.now().millisecondsSinceEpoch}';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final snapshot = await storageRef.putBlob(file).whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading banner image: $e");
      return null;
    }
  }
}
