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
          print('\n🔥 FIRESTORE INITIAL LOAD 🔥');
          print('Doc ID: ${doc.id}');
          print('benefits field: ${data["benefits"]}');
          print('benefits type: ${data["benefits"]?.runtimeType}');
          print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥\n');
          _duaController.addDuaToList(DuaModel.fromMap(data));
        }
      } else {
        // Handle individual document changes
        event.docChanges.forEach((element) {
          if (element.type == DocumentChangeType.added ||
              element.type == DocumentChangeType.modified) {
            final data = element.doc.data()!;
            print('\n🔥 FIRESTORE DATA RECEIVED 🔥');
            print('Doc ID: ${element.doc.id}');
            print('Data keys: ${data.keys.toList()}');
            print('benefits field: ${data["benefits"]}');
            print('benefits type: ${data["benefits"]?.runtimeType}');
            print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥\n');
            _duaController.addDuaToList(DuaModel.fromMap(data));
          }
        });
      }
    });
  }
}
