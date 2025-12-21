import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;

final userRef = firestore.collection('Users');
final managementRef = firestore.collection('Management');
final categoryRef = firestore.collection('Category');
final subCategoryRef = firestore.collection('SubCategory');
final duaRef = firestore.collection('Dua');
final notificationRef = firestore.collection('Notifications');
final sysConfigRef = firestore.collection('SystemConfiguration');
