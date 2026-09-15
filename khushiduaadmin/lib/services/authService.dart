import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/firebaseRef.dart';
import '../models/managementModel.dart';

enum AdminSignInStatus { signedIn, notAnAdmin, cancelled, failed }

class AdminSignInResult {
  const AdminSignInResult(
    this.status, {
    this.admin,
    this.email,
    this.uid,
    this.message,
  });

  final AdminSignInStatus status;
  final ManagementModel? admin;

  /// Shown on the "not an admin" panel, so the account can be invited — or,
  /// for the very first super admin, added in the Firebase Console.
  final String? email;
  final String? uid;
  final String? message;
}

/// Admin sign-in. There are no admin passwords: a Google account is an admin
/// only if /Management/{uid} exists, and only Cloud Functions write that.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: "us-central1");

  Future<AdminSignInResult> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      final credential = await _auth.signInWithPopup(provider);
      final user = credential.user;
      if (user == null) {
        return const AdminSignInResult(AdminSignInStatus.failed,
            message: "Sign-in didn't complete. Try again.");
      }
      return await resolveAdmin(user);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return const AdminSignInResult(AdminSignInStatus.cancelled);
        case 'popup-blocked':
          return const AdminSignInResult(AdminSignInStatus.failed,
              message:
                  "Your browser blocked the sign-in window. Allow pop-ups for this site and try again.");
        case 'account-exists-with-different-credential':
          return const AdminSignInResult(AdminSignInStatus.failed,
              message:
                  "This email already has a password login. Delete that user in Firebase Console → Authentication, then sign in with Google again.");
        default:
          return AdminSignInResult(AdminSignInStatus.failed,
              message: e.message ?? "Sign-in failed (${e.code}).");
      }
    }
  }

  /// Loads the admin record for [user], claiming a pending invite first if
  /// there is one. Signs non-admins straight back out so their session never
  /// lingers in the browser.
  Future<AdminSignInResult> resolveAdmin(User user) async {
    var doc = await managementRef.doc(user.uid).get();

    if (!doc.exists) {
      try {
        final result =
            await _functions.httpsCallable("claimAdminInvite").call();
        final data = Map<String, dynamic>.from(result.data as Map);
        if (data["claimed"] == true) {
          doc = await managementRef.doc(user.uid).get();
        }
      } on FirebaseFunctionsException catch (e) {
        debugPrint("claimAdminInvite: ${e.code} ${e.message}");
      }
    }

    final data = doc.data();
    if (doc.exists && data != null) {
      return AdminSignInResult(AdminSignInStatus.signedIn,
          admin: ManagementModel.fromMap(data));
    }

    final email = user.email;
    final uid = user.uid;
    await _auth.signOut();
    return AdminSignInResult(AdminSignInStatus.notAnAdmin,
        email: email, uid: uid);
  }

  /// The admin behind Firebase's persisted browser session, or null.
  Future<ManagementModel?> restoreSession() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    return (await resolveAdmin(user)).admin;
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> inviteAdmin({
    required String email,
    required String role,
    required String firstName,
    required String lastName,
  }) =>
      _call("inviteAdmin", {
        "email": email,
        "role": role,
        "firstName": firstName,
        "lastName": lastName,
      });

  Future<String?> cancelInvite(String email) =>
      _call("cancelInvite", {"email": email});

  Future<String?> revokeAdmin(String uid) =>
      _call("revokeAdmin", {"uid": uid});

  /// Null on success, otherwise a message fit to show the admin.
  Future<String?> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? "Request failed (${e.code}).";
    } catch (e) {
      return "Request failed: $e";
    }
  }
}
