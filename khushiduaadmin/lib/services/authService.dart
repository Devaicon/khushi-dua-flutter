import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/controllers/authController.dart';
import 'dart:html' as html;
import '../constants/firebaseRef.dart';
import '../models/managementModel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();

  createAdmin() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: "admin@gmail.com",
        password: "123456",
      );
      ManagementModel managementModel = ManagementModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: "Super_Admin",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          firstName: 'Admin',
          lastName: 'John');
      await managementRef.doc(managementModel.id).set(managementModel.toMap());
    } on FirebaseAuthException catch (e) {
      debugPrint('Error creating admin: ${e.message}');
    }
  }

  Future<void> login(String email, String password) async {
    _authController.setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      html.window.localStorage['adminId'] = userCredential.user!.uid;
      await managementRef.doc(userCredential.user!.uid).get().then((value) {
        _authController
            .setManagementUserModel(ManagementModel.fromMap(value.data()!));
        _authController.setLoading(false);
        Get.offAllNamed('/dashboard');
      });
    } on FirebaseAuthException {
      debugPrint("Error logging in");
      _authController.setLoading(false);
    }
  }

  getAdminDetails() async {
    String? adminId = html.window.localStorage['adminId'];
    if (adminId == null) return;

    try {
      var snapshot = await managementRef.doc(adminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        _authController
            .setManagementUserModel(ManagementModel.fromMap(snapshot.data()!));
      } else {
        debugPrint("Admin document does not exist, clearing session.");
        html.window.localStorage.remove('adminId');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
    }
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return "No user logged in";
      }

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return "Current password is incorrect";
      } else if (e.code == 'weak-password') {
        return "New password is too weak";
      } else {
        return "Error changing password: ${e.message}";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  Future<String?> createNewAdmin(String email, String password,
      String firstName, String lastName, String role) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      ManagementModel managementModel = ManagementModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: role.isEmpty ? "Admin" : role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          firstName: firstName,
          lastName: lastName);

      await managementRef.doc(managementModel.id).set(managementModel.toMap());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "Password is too weak";
      } else if (e.code == 'email-already-in-use') {
        return "Email is already in use";
      } else if (e.code == 'invalid-email') {
        return "Invalid email address";
      } else {
        return "Error creating admin: ${e.message}";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
