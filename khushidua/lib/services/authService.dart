import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  static bool _googleInitialised = false;

  /// Signs in with Google, creating the user's profile on first use.
  ///
  /// An email that already has a password account normally needs no special
  /// handling: Google is a trusted provider for its own addresses, so Firebase
  /// signs straight into the existing account and the user keeps their points
  /// and progress. Firebase raises `account-exists-with-different-credential`
  /// only when it will not do that automatically; then the user confirms their
  /// password once and the Google credential is linked to the same account.
  Future<void> signInWithGoogle() async {
    final auth = FirebaseAuth.instance;
    final google = GoogleSignIn.instance;

    final AuthCredential credential;
    try {
      if (!_googleInitialised) {
        await google.initialize();
        _googleInitialised = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google returned no ID token');
      credential = GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint("Google sign-in error: ${e.code} ${e.description}");
      CustomSnackbar.show(
        "Error",
        _isMissingGoogleConfig(e)
            ? "Google sign-in is not set up for this app yet.".tr
            : "Google sign-in failed. Please try again.".tr,
        isSuccess: false,
      );
      return;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      CustomSnackbar.show(
        "Error",
        "Google sign-in failed. Please try again.".tr,
        isSuccess: false,
      );
      return;
    }

    try {
      final result = await auth.signInWithCredential(credential);
      await _completeSocialSignIn(result);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' &&
          e.email != null) {
        await _linkGoogleToPasswordAccount(e.email!, credential);
        return;
      }
      debugPrint("Firebase Google sign-in error: ${e.code}");
      CustomSnackbar.show("Error", _authErrorMessage(e), isSuccess: false);
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      CustomSnackbar.show(
        "Error",
        "An unexpected error occurred".tr,
        isSuccess: false,
      );
    }
  }

  /// A missing web client id surfaces as a configuration error rather than a
  /// user-facing failure; this is what happens until Google is enabled in the
  /// Firebase console and the config files are downloaded again.
  bool _isMissingGoogleConfig(GoogleSignInException e) {
    if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        e.code == GoogleSignInExceptionCode.providerConfigurationError) {
      return true;
    }
    final text = (e.description ?? '').toLowerCase();
    return text.contains('serverclientid') || text.contains('client id');
  }

  Future<void> _linkGoogleToPasswordAccount(
    String email,
    AuthCredential googleCredential,
  ) async {
    final password = await _askForPassword(email);
    if (password == null) return;

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user!.linkWithCredential(googleCredential);
      await _completeSocialSignIn(result);
      CustomSnackbar.show("Success", "Google is now linked to your account".tr);
    } on FirebaseAuthException catch (e) {
      debugPrint("Link Google error: ${e.code}");
      CustomSnackbar.show("Error", _authErrorMessage(e), isSuccess: false);
    }
  }

  Future<String?> _askForPassword(String email) {
    final controller = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        title: Text("Link your Google account".tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You already have an account with this email. Enter its password to use Google sign-in with it too."
                  .tr,
            ),
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(hintText: "Password".tr),
              onSubmitted: (value) => Get.back(result: value),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel".tr)),
          TextButton(
            onPressed: () => Get.back(result: controller.text),
            child: Text("Link account".tr),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// Shared tail of every non-password sign-in: make sure a profile exists,
  /// record the device token, then enter the app.
  Future<void> _completeSocialSignIn(UserCredential result) async {
    final user = result.user!;
    final prefs = await SharedPreferences.getInstance();
    final doc = await userRef.doc(user.uid).get();
    final fcmToken = await getFCMToken().timeout(
      const Duration(seconds: 10),
      onTimeout: () => '',
    );

    if (!doc.exists) {
      final profile = UserModel(
        id: user.uid,
        name: user.displayName ?? (user.email ?? '').split('@').first,
        email: user.email ?? '',
        points: prefs.getInt("userPoints") ?? 0,
        isLoggedIn: true,
        isMember: false,
        readDuas: [],
        avatar: _userController.avatar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fcmToken: fcmToken,
        isBlocked: false,
      );
      await userRef.doc(user.uid).set(profile.toMap());
    } else {
      await userRef.doc(user.uid).update({
        "fcmToken": fcmToken,
        "isLoggedIn": true,
      });
    }

    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("userId", user.uid);
    _userController.setLoggedIn(true);
    await getUserData(user.uid);
    Get.find<NotificationController>().getAllNotifications(userId: user.uid);
    Get.offAll(() => const Dashboard());
    CustomSnackbar.show("Success", "Login successful".tr);
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return "Wrong password provided.".tr;
      case 'invalid-credential':
      case 'user-not-found':
        return "Invalid email or password.".tr;
      case 'user-disabled':
        return "This user has been disabled.".tr;
      case 'network-request-failed':
        return "Network error. Please check your internet connection.".tr;
      case 'too-many-requests':
        return "Too many failed attempts. Please try again later.".tr;
      case 'credential-already-in-use':
        return "This Google account is already linked to another user.".tr;
      default:
        return "Something went wrong. Try again later".tr;
    }
  }

  /// The one live listener on the signed-in user's document. Sign-in and the
  /// dashboard both ask for user data, and each call used to open another
  /// listener that was never closed; after switching accounts the previous
  /// user's listener kept pushing their readDuas into the app.
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userSubscription;
  static String? _subscribedUserId;

  getUserData(String userId) async {
    if (_subscribedUserId == userId && _userSubscription != null) return;
    await _userSubscription?.cancel();
    _subscribedUserId = userId;
    _userSubscription = userRef.doc(userId).snapshots().listen((event) {
      final data = event.data();
      if (data == null) return;
      final userModel = UserModel.fromMap(data);
      _userController.setUserModel(userModel);

      if (userModel.isBlocked) {
        Get.offAll(() => BlockedScreen());
      }
    });
  }

  /// Stops listening to the user document, signs out of Firebase and forgets
  /// the user, so the app goes back to guest state straight away.
  Future<void> signOut() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    _subscribedUserId = null;
    try {
      await FirebaseAuth.instance.signOut();
      if (_googleInitialised) await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
    _userController.clearUserModel();
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
