import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/models/duaModel.dart';

import '../widgets/customSnackbar.dart';

class DuaService {
  final DuaController _duaController = Get.find<DuaController>();

  getAllDuas() async {
    duaRef.snapshots().listen((event) {
      bool changed = false;
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _duaController.addDuaToList(
            DuaModel.fromMap(element.doc.data()!),
            shouldUpdate: false,
          );
          changed = true;
        }
      }
      if (changed) {
        _duaController.update();
      }
    });
  }

  createDua(DuaModel duaModel, File grownUpmp3File, File littleKidmp3File,
      File olderKidmp3File) async {
    _duaController.setLoading(true);
    duaModel.id = duaRef.doc().id;
    try {
      debugPrint("=========================================");
      debugPrint("CREATING NEW DUA");
      debugPrint("=========================================");
      debugPrint("Generated Dua ID: ${duaModel.id}");
      debugPrint("Firestore Path: /Dua/${duaModel.id}");
      debugPrint("-----------------------------------------");

      duaModel.olderKidsAudio = (await uploadFileToFirebase(
          olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
      duaModel.littleKidsAudio = (await uploadFileToFirebase(
          littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
      duaModel.grownUpsAudio = (await uploadFileToFirebase(
          grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;

      final duaMap = duaModel.toMap();
      duaRef.doc(duaModel.id).set(duaMap);

      debugPrint("Dua Data Saved Successfully!");
      debugPrint("-----------------------------------------");
      debugPrint("COMPLETE DUA DATA:");
      debugPrint("ID: ${duaModel.id}");
      debugPrint("Arabic: ${duaModel.arabic}");
      debugPrint("English: ${duaModel.english}");
      debugPrint("Transliteration: ${duaModel.transliteration}");
      debugPrint("Description: ${duaModel.description ?? 'N/A'}");
      debugPrint("Benefits: ${duaModel.benefits ?? 'N/A'}");
      debugPrint("Order: ${duaModel.order}");
      debugPrint("SubCategoryIds: ${duaModel.subCategoryIds}");
      debugPrint("LittleKids: ${duaModel.littleKids}");
      debugPrint("OlderKids: ${duaModel.olderKids}");
      debugPrint("GrownUps: ${duaModel.grownUps}");
      debugPrint("IsEnabled: ${duaModel.isEnabled}");
      debugPrint("CreatedAt: ${duaModel.createdAt}");
      debugPrint("UpdatedAt: ${duaModel.updatedAt}");
      debugPrint("LittleKidsAudio: ${duaModel.littleKidsAudio}");
      debugPrint("OlderKidsAudio: ${duaModel.olderKidsAudio}");
      debugPrint("GrownUpsAudio: ${duaModel.grownUpsAudio}");
      debugPrint("-----------------------------------------");
      debugPrint("ALL FIELDS (JSON):");
      duaMap.forEach((key, value) {
        if (value is String && value.length > 100) {
          debugPrint("$key: ${value.substring(0, 100)}... (truncated)");
        } else {
          debugPrint("$key: $value");
        }
      });
      debugPrint("=========================================");

      _duaController.setLoading(false);
      Get.back();
      CustomSnackbar.show(
          "Success", "Dua added successfully!\nID: ${duaModel.id}");
    } catch (e) {
      debugPrint("ERROR CREATING DUA: $e");
      _duaController.setLoading(false);
      CustomSnackbar.show("Error", "Something went wrong", isSuccess: false);
      return false;
    }
  }

  updateDua(DuaModel duaModel, File? grownUpmp3File, File? littleKidmp3File,
      File? olderKidmp3File, File? englishTrans, File? urduTrans) async {
    _duaController.setLoading(true);
    debugPrint("=========================================");
    debugPrint("UPDATING DUA");
    debugPrint("=========================================");
    debugPrint("Dua ID: ${duaModel.id}");
    debugPrint("Firestore Path: /Dua/${duaModel.id}");
    debugPrint("-----------------------------------------");

    if (grownUpmp3File != null) {
      duaModel.grownUpsAudio = (await uploadFileToFirebase(
          grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;
      debugPrint("Updated GrownUpsAudio");
    }
    if (littleKidmp3File != null) {
      duaModel.littleKidsAudio = (await uploadFileToFirebase(
          littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
      debugPrint("Updated LittleKidsAudio");
    }
    if (olderKidmp3File != null) {
      duaModel.olderKidsAudio = (await uploadFileToFirebase(
          olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
      debugPrint("Updated OlderKidsAudio");
    }
    if (englishTrans != null) {
      duaModel.englishTranslation = (await uploadFileToFirebase(
          englishTrans, "${duaModel.id}/englishTransAudio"))!;
      debugPrint("Updated EnglishTranslationAudio");
    }
    if (urduTrans != null) {
      duaModel.urduTranslation = (await uploadFileToFirebase(
          urduTrans, "${duaModel.id}/urduTransAudio"))!;
      debugPrint("Updated UrduTranslationAudio");
    }

    // Use set with merge to ensure all fields including benefits are saved
    final duaMap = duaModel.toMap();
    await duaRef.doc(duaModel.id).set(duaMap, SetOptions(merge: true));

    debugPrint("Dua Data Updated Successfully!");
    debugPrint("-----------------------------------------");
    debugPrint("COMPLETE UPDATED DUA DATA:");
    debugPrint("ID: ${duaModel.id}");
    debugPrint("Arabic: ${duaModel.arabic}");
    debugPrint("English: ${duaModel.english}");
    debugPrint("Transliteration: ${duaModel.transliteration}");
    debugPrint("Description: ${duaModel.description ?? 'N/A'}");
    debugPrint("Benefits: ${duaModel.benefits ?? 'N/A'}");
    debugPrint("Order: ${duaModel.order}");
    debugPrint("SubCategoryIds: ${duaModel.subCategoryIds}");
    debugPrint("LittleKids: ${duaModel.littleKids}");
    debugPrint("OlderKids: ${duaModel.olderKids}");
    debugPrint("GrownUps: ${duaModel.grownUps}");
    debugPrint("IsEnabled: ${duaModel.isEnabled}");
    debugPrint("UpdatedAt: ${duaModel.updatedAt}");
    debugPrint("LittleKidsAudio: ${duaModel.littleKidsAudio}");
    debugPrint("OlderKidsAudio: ${duaModel.olderKidsAudio}");
    debugPrint("GrownUpsAudio: ${duaModel.grownUpsAudio}");
    debugPrint("EnglishTranslation: ${duaModel.englishTranslation ?? 'N/A'}");
    debugPrint("UrduTranslation: ${duaModel.urduTranslation ?? 'N/A'}");
    debugPrint("-----------------------------------------");
    debugPrint("ALL FIELDS (JSON):");
    duaMap.forEach((key, value) {
      if (value is String && value.length > 100) {
        debugPrint("$key: ${value.substring(0, 100)}... (truncated)");
      } else {
        debugPrint("$key: $value");
      }
    });
    debugPrint("=========================================");

    _duaController.setLoading(false);
    Get.back();
    CustomSnackbar.show(
        "Success", "Dua updated successfully!\nID: ${duaModel.id}");
  }

  Future<String?> uploadFileToFirebase(File file, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);

      final uploadTask = storageRef.putBlob(file);

      final snapshot = await uploadTask.whenComplete(() {});

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading file: $e");
      return null;
    }
  }
}
