import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/duaController.dart';
import 'package:khushiduaadmin/models/duaModel.dart';

import '../widgets/customSnackbar.dart';

class DuaService{
  DuaController _duaController=Get.find<DuaController>();

   getAllDuas() {
     duaRef.snapshots().listen((event) {
       event.docChanges.forEach((element) {
         if (element.type == DocumentChangeType.added || element.type == DocumentChangeType.modified) {
           _duaController.addDuaToList(DuaModel.fromMap(element.doc.data()!));
         }
       });
     });
   }

   createDua(DuaModel duaModel, File grownUpmp3File, File littleKidmp3File, File olderKidmp3File) async{
     _duaController.setLoading(true);
     duaModel.id=await duaRef.doc().id;
     try{
       print("=========================================");
       print("CREATING NEW DUA");
       print("=========================================");
       print("Generated Dua ID: ${duaModel.id}");
       print("Firestore Path: /Dua/${duaModel.id}");
       print("-----------------------------------------");
       
       duaModel.olderKidsAudio=(await uploadFileToFirebase(olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
       duaModel.littleKidsAudio=(await uploadFileToFirebase(littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
       duaModel.grownUpsAudio=(await uploadFileToFirebase(grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;
       
       final duaMap = duaModel.toMap();
       duaRef.doc(duaModel.id).set(duaMap);
       
       print("Dua Data Saved Successfully!");
       print("-----------------------------------------");
       print("COMPLETE DUA DATA:");
       print("ID: ${duaModel.id}");
       print("Arabic: ${duaModel.arabic}");
       print("English: ${duaModel.english}");
       print("Transliteration: ${duaModel.transliteration}");
       print("Description: ${duaModel.description ?? 'N/A'}");
       print("Benefits: ${duaModel.benefits ?? 'N/A'}");
       print("Order: ${duaModel.order}");
       print("SubCategoryIds: ${duaModel.subCategoryIds}");
       print("LittleKids: ${duaModel.littleKids}");
       print("OlderKids: ${duaModel.olderKids}");
       print("GrownUps: ${duaModel.grownUps}");
       print("IsEnabled: ${duaModel.isEnabled}");
       print("CreatedAt: ${duaModel.createdAt}");
       print("UpdatedAt: ${duaModel.updatedAt}");
       print("LittleKidsAudio: ${duaModel.littleKidsAudio}");
       print("OlderKidsAudio: ${duaModel.olderKidsAudio}");
       print("GrownUpsAudio: ${duaModel.grownUpsAudio}");
       print("-----------------------------------------");
       print("ALL FIELDS (JSON):");
       duaMap.forEach((key, value) {
         if (value is String && value.length > 100) {
           print("$key: ${value.substring(0, 100)}... (truncated)");
         } else {
           print("$key: $value");
         }
       });
       print("=========================================");
       
       _duaController.setLoading(false);
       Get.back();
       CustomSnackbar.show("Success", "Dua added successfully!\nID: ${duaModel.id}");
     }catch (e){
       print("ERROR CREATING DUA: $e");
       _duaController.setLoading(false);
       CustomSnackbar.show("Error", "Something went wrong", isSuccess: false);
       return false;
     }
   }
   updateDua(DuaModel duaModel, File? grownUpmp3File, File? littleKidmp3File, File? olderKidmp3File,File? englishTrans, File? urduTrans)async{
     _duaController.setLoading(true);
     print("=========================================");
     print("UPDATING DUA");
     print("=========================================");
     print("Dua ID: ${duaModel.id}");
     print("Firestore Path: /Dua/${duaModel.id}");
     print("-----------------------------------------");
     
     if(grownUpmp3File!=null){
       duaModel.grownUpsAudio=(await uploadFileToFirebase(grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;
       print("Updated GrownUpsAudio");
     }
     if(littleKidmp3File!=null){
       duaModel.littleKidsAudio=(await uploadFileToFirebase(littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
       print("Updated LittleKidsAudio");
     }
     if(olderKidmp3File!=null){
       duaModel.olderKidsAudio=(await uploadFileToFirebase(olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
       print("Updated OlderKidsAudio");
     }
     if(englishTrans!=null){
       duaModel.englishTranslation=(await uploadFileToFirebase(englishTrans, "${duaModel.id}/englishTransAudio"))!;
       print("Updated EnglishTranslationAudio");
     }
     if(urduTrans!=null){
       duaModel.urduTranslation=(await uploadFileToFirebase(urduTrans, "${duaModel.id}/urduTransAudio"))!;
       print("Updated UrduTranslationAudio");
     }

     // Use set with merge to ensure all fields including benefits are saved
     final duaMap = duaModel.toMap();
     await duaRef.doc(duaModel.id).set(duaMap, SetOptions(merge: true));
     
     print("Dua Data Updated Successfully!");
     print("-----------------------------------------");
     print("COMPLETE UPDATED DUA DATA:");
     print("ID: ${duaModel.id}");
     print("Arabic: ${duaModel.arabic}");
     print("English: ${duaModel.english}");
     print("Transliteration: ${duaModel.transliteration}");
     print("Description: ${duaModel.description ?? 'N/A'}");
     print("Benefits: ${duaModel.benefits ?? 'N/A'}");
     print("Order: ${duaModel.order}");
     print("SubCategoryIds: ${duaModel.subCategoryIds}");
     print("LittleKids: ${duaModel.littleKids}");
     print("OlderKids: ${duaModel.olderKids}");
     print("GrownUps: ${duaModel.grownUps}");
     print("IsEnabled: ${duaModel.isEnabled}");
     print("UpdatedAt: ${duaModel.updatedAt}");
     print("LittleKidsAudio: ${duaModel.littleKidsAudio}");
     print("OlderKidsAudio: ${duaModel.olderKidsAudio}");
     print("GrownUpsAudio: ${duaModel.grownUpsAudio}");
     print("EnglishTranslation: ${duaModel.englishTranslation ?? 'N/A'}");
     print("UrduTranslation: ${duaModel.urduTranslation ?? 'N/A'}");
     print("-----------------------------------------");
     print("ALL FIELDS (JSON):");
     duaMap.forEach((key, value) {
       if (value is String && value.length > 100) {
         print("$key: ${value.substring(0, 100)}... (truncated)");
       } else {
         print("$key: $value");
       }
     });
     print("=========================================");
     
     _duaController.setLoading(false);
     Get.back();
     CustomSnackbar.show("Success", "Dua updated successfully!\nID: ${duaModel.id}");
   }

  Future<String?> uploadFileToFirebase(File file, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);

      final uploadTask = storageRef.putBlob(file);

      final snapshot = await uploadTask.whenComplete(() {});

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }


}