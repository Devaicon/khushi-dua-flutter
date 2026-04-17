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

    try {
      // For iOS, we need to ensure APNS token is available first
      if (Platform.isIOS) {
        // Request notification permissions
        NotificationSettings settings = await firebaseMessaging
            .requestPermission(alert: true, badge: true, sound: true);

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('User granted permission');
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          debugPrint('User granted provisional permission');
        } else {
          debugPrint('User declined or has not accepted permission');
        }

        // Wait for APNS token to be available with timeout and retries
        String? apnsToken;
        int attempts = 0;
        while (apnsToken == null && attempts < 5) {
          try {
            apnsToken = await firebaseMessaging.getAPNSToken();
          } catch (e) {
            debugPrint("Error getting APNS token (attempt $attempts): $e");
          }
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
          }
        }

        if (apnsToken != null) {
          debugPrint("APNS Token: $apnsToken");
        } else {
          debugPrint(
            "APNS Token not available after retries (expected on iOS Simulator)",
          );
          // On simulator, continue anyway - FCM token might still work
        }
      }

      // Get FCM token with timeout
      String? token;
      try {
        token = await firebaseMessaging.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("FCM token request timed out");
            return null;
          },
        );
      } catch (e) {
        debugPrint("Error getting FCM token (expected on iOS Simulator): $e");
        token = null;
      }

      debugPrint(
        "FCM TOKEN: ${token ?? 'Not available (simulator or no permission)'}",
      );
      return token ?? '';
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return ''; // Return empty string instead of failing
    }
  }

  register(String email, String password, String name) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get FCM token but don't fail registration if it's not available
      String fcmToken = '';
      try {
        fcmToken = await getFCMToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => '',
        );
      } catch (e) {
        debugPrint("FCM token error during registration: $e");
      }

      UserModel user = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        points: await prefs.getInt("userPoints") ?? 0,
        isLoggedIn: true,
        isMember: false,
        readDuas: [],
        avatar: _userController.avatar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fcmToken: fcmToken,
        isBlocked: false,
      );

      await userRef.doc(user.id).set(user.toMap());
      _userController.setLoggedIn(true);
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("userId", user.id);
      _userController.setLoggedIn(true);
      await getUserData(userCredential.user!.uid);
      Get.find<NotificationController>().getAllNotifications();
      Get.offAll(() => const Dashboard());
      CustomSnackbar.show("Success", "Signed up successfully".tr);
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Register Error: ${e.code}");
      String errorMessage = "Something went wrong. Try again later".tr;
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.".tr;
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.".tr;
      } else if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.".tr;
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            "Network error. Please check your internet connection.".tr;
      }
      CustomSnackbar.show("Error", errorMessage, isSuccess: false);
    } catch (e) {
      debugPrint("Register Error: $e");
      CustomSnackbar.show(
        "Error",
        "An unexpected error occurred".tr,
        isSuccess: false,
      );
    }
  }

  login(String email, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
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
      debugPrint("Firebase Auth Login Error: ${e.code}");
      String errorMessage = "Something went wrong. Try again later".tr;
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = "Invalid email or password.".tr;
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.".tr;
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.".tr;
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            "Network error. Please check your internet connection.".tr;
      } else if (e.code == 'user-disabled') {
        errorMessage = "This user has been disabled.".tr;
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many failed attempts. Please try again later.".tr;
      }
      CustomSnackbar.show("Error", errorMessage, isSuccess: false);
    } catch (e) {
      debugPrint("Login Error: $e");
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      CustomSnackbar.show(
        "Success",
        "Password reset email sent. Please check your inbox.".tr,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Failed to send reset email.".tr;
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.".tr;
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.".tr;
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
}
