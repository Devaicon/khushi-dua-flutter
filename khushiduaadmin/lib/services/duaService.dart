import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
       duaModel.olderKidsAudio=(await uploadFileToFirebase(olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
       duaModel.littleKidsAudio=(await uploadFileToFirebase(littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
       duaModel.grownUpsAudio=(await uploadFileToFirebase(grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;
       duaRef.doc(duaModel.id).set(duaModel.toMap());
       _duaController.setLoading(false);
       Get.back();
       CustomSnackbar.show("Success", "Dua added successfully");
     }catch (e){
       _duaController.setLoading(false);
       CustomSnackbar.show("Error", "Something went wrong", isSuccess: false);
       return false;
     }
   }
   updateDua(DuaModel duaModel, File? grownUpmp3File, File? littleKidmp3File, File? olderKidmp3File,File? englishTrans, File? urduTrans)async{
     _duaController.setLoading(true);
     if(grownUpmp3File!=null){
       duaModel.grownUpsAudio=(await uploadFileToFirebase(grownUpmp3File, "${duaModel.id}/grownUpsAudio"))!;
     }
     if(littleKidmp3File!=null){
       duaModel.littleKidsAudio=(await uploadFileToFirebase(littleKidmp3File, "${duaModel.id}/littleKidsAudio"))!;
     }
     if(olderKidmp3File!=null){
       duaModel.olderKidsAudio=(await uploadFileToFirebase(olderKidmp3File, "${duaModel.id}/olderKidsAudio"))!;
     }
     if(englishTrans!=null){
       duaModel.englishTranslation=(await uploadFileToFirebase(englishTrans, "${duaModel.id}/englishTransAudio"))!;
     }
     if(urduTrans!=null){
       duaModel.urduTranslation=(await uploadFileToFirebase(urduTrans, "${duaModel.id}/urduTransAudio"))!;
     }

     // Use set with merge to ensure all fields including benefits are saved
     await duaRef.doc(duaModel.id).set(duaModel.toMap(), SetOptions(merge: true));
     _duaController.setLoading(false);
     Get.back();
     CustomSnackbar.show("Success", "Dua updated successfully");
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