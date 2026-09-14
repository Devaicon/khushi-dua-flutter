import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/initController.dart';
import 'package:khushiduaadmin/views/auth/login.dart';
import 'package:khushiduaadmin/views/dashboard.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("Starting app initialization...");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized");
  } catch (e) {
    debugPrint("Firebase error: $e");
  }

  String? adminId;
  if (kIsWeb) {
    try {
      adminId = html.window.localStorage['adminId'];
    } catch (e) {
      debugPrint("Storage error: $e");
    }
  }

  String initialRoute = adminId == null ? '/login' : '/dashboard';
  debugPrint("Initial route determined: $initialRoute");

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Khushi Dua Admin',
      debugShowCheckedModeBanner: false,
      initialBinding: InitController(),
      initialRoute: initialRoute,
      getPages: [
        GetPage(
          name: '/',
          page: () => initialRoute == '/dashboard'
              ? const DashboardScreen()
              : const LoginScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fade,
        ),
        GetPage(
          name: '/dashboard',
          page: () => const DashboardScreen(),
          transition: Transition.fade,
        ),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xff1E1E1E),
        useMaterial3: true,
      ),
    );
  }
}
