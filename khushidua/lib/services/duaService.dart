import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/models/duaModel.dart';

class DuaService {
  final DuaController _duaController = Get.find<DuaController>();

  getAllDuas() {
    duaRef.snapshots().listen((event) {
      // Handle initial load (all documents) and updates
      if (event.docChanges.isEmpty) {
        // This is the initial load - process all documents
        for (var doc in event.docs) {
          final data = doc.data();
          _duaController.addDuaToList(DuaModel.fromMap(data));
        }
      } else {
        // Handle individual document changes
        event.docChanges.forEach((element) {
          if (element.type == DocumentChangeType.added ||
              element.type == DocumentChangeType.modified) {
            final data = element.doc.data()!;
            _duaController.addDuaToList(DuaModel.fromMap(data));
          }
        });
      }
    });
  }
}
