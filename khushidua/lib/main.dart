import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:khushidua/views/dashboard.dart';

import 'constants/theme.dart';
import 'controllers/initController.dart';
import 'controllers/themeController.dart';
import 'services/reminderService.dart';
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

  // Content is served from this cache between admin edits, so it must not be
  // evicted by the default 100 MB limit.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications for the Azkar and Salah reminders. Awaited so a
  // notification that launched the app is captured before the first frame.
  await ReminderService.instance.init();

  // Before runApp, so ThemeController starts on the reader's last age group.
  await ThemeController.loadSavedAgeGroup();

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
      theme: buildAppTheme(),
      // Every route sits on the page colour, so no edge of the screen — the
      // strip a SafeArea leaves, or a route mid-transition — ever shows the
      // window's black dark-mode background.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: kAppOverlayStyle,
        child: ColoredBox(
          color: AppSurface.page,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      defaultTransition: Transition.cupertino,
      transitionDuration: AppMotion.base,
      home: Dashboard(),
    );
  }
}
