import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/initController.dart';
import 'package:khushiduaadmin/views/auth/login.dart';
import 'package:khushiduaadmin/views/dashboard.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Firebase persists the admin's session in the browser. The dashboard
  // re-checks /Management on open, so a non-admin session is sent back here.
  String initialRoute = '/login';
  try {
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user != null) initialRoute = '/dashboard';
  } catch (e) {
    debugPrint("Auth restore error: $e");
  }
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
