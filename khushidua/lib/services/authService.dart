import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushidua/constants/firebaseRef.dart';
import 'package:khushidua/controllers/userController.dart';
import 'package:khushidua/models/userModel.dart';
import 'package:khushidua/widgets/customSnackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/notificationController.dart';
import '../views/blockedScreen.dart';
import '../views/dashboard.dart';

class AuthService {
  final UserController _userController = Get.find<UserController>();

  Future<String> getFCMToken() async {
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    // For iOS, we need to ensure APNS token is available first
    if (Platform.isIOS) {
      // Request notification permissions
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Wait for APNS token to be available
      String? apnsToken = await firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        // Wait a bit and try again
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await firebaseMessaging.getAPNSToken();
      }
      debugPrint("APNS Token: $apnsToken");
    }

    String? token = await firebaseMessaging.getToken();
    debugPrint("FCM TOKEN: $token");
    return token ?? '';
  }

  register(String email, String password, String name) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();

      UserModel user = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        points: await prefs.getInt("userPoints") ?? 0,
        isLoggedIn: true,
        isMember: false,
        readDuas: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fcmToken: await getFCMToken(),
        isBlocked: false,
      );
      userRef.doc(user.id).set(user.toMap());
      _userController.setLoggedIn(true);
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("userId", user.id);
      _userController.setLoggedIn(true);
      await getUserData(userCredential.user!.uid);
      Get.find<NotificationController>().getAllNotifications();
      Get.offAll(() => const Dashboard());
      CustomSnackbar.show("Success", "Signed up successfully".tr);
    } on FirebaseAuthException {
      CustomSnackbar.show(
        "Error",
        "Something went wrong. Try again later",
        isSuccess: false,
      );
      // _authController.setLoading(false);
    }
  }

  login(String email, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      prefs.setString("userId", userCredential.user!.uid);
      _userController.setLoggedIn(true);
      await userRef.doc(userCredential.user!.uid).update({
        "fcmToken": await getFCMToken(),
        "isLoggedIn": true,
      });
      getUserData(userCredential.user!.uid);
      Get.find<NotificationController>().getAllNotifications();
      Get.offAll(() => const Dashboard());
      CustomSnackbar.show("Success", "Login successful".tr);
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Something went wrong. Try again later".tr;
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.".tr;
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.".tr;
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.".tr;
      }
      CustomSnackbar.show("Error", errorMessage, isSuccess: false);
    } catch (e) {
      CustomSnackbar.show(
        "Error",
        "An unexpected error occurred".tr,
        isSuccess: false,
      );
    }
  }

  getUserData(String userId) async {
    await userRef.doc(userId).snapshots().listen((event) {
      final userModel = UserModel.fromMap(event.data()!);
      _userController.setUserModel(userModel);

      if (userModel.isBlocked) {
        Get.offAll(() => BlockedScreen());
      }
    });
  }
}
