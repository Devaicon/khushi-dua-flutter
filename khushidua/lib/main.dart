import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:khushidua/views/dashboard.dart';

import 'controllers/initController.dart';
import 'controllers/localization.dart';
import 'firebase_options.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  MobileAds.instance
      .initialize()
      .then((InitializationStatus status) {
        debugPrint('AdMob initialized: ${status.adapterStatuses}');
      })
      .catchError((e) {
        debugPrint('AdMob initialization failed: $e');
      });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Khushi Dua Book',
      navigatorKey: Get.key,
      initialBinding: InitControllers(),
      translations: Localization(),
      locale: Locale('en', 'US'),
      fallbackLocale: Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      home: Dashboard(),
    );
  }
}
