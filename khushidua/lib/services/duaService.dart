import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/models/duaModel.dart';

class DuaService {
  final DuaController _duaController = Get.find<DuaController>();

  getAllDuas() {
    duaRef.snapshots().listen((event) {
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _duaController.addDuaToList(DuaModel.fromMap(element.doc.data()!));
        }
      });
    });
  }
}
