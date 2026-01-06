import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:khushiduaadmin/constants/firebaseRef.dart';
import 'package:khushiduaadmin/controllers/notificationController.dart';
import 'package:khushiduaadmin/controllers/userController.dart';
import 'package:khushiduaadmin/models/notificationModel.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:khushiduaadmin/models/userModel.dart';

import '../widgets/customSnackbar.dart';

class NotificationService {
  final NotificationController _notificationController =
      Get.find<NotificationController>();
  final UserController _userController = Get.find<UserController>();

  getAllNotifications() async {
    notificationRef.snapshots().listen((event) {
      bool changed = false;
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          _notificationController.addNotificationToList(
            NotificationModel.fromMap(element.doc.data()!),
            shouldUpdate: false,
          );
          changed = true;
        }
      }
      if (changed) _notificationController.update();
    });
  }

  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "khushidua",
      "private_key_id": "996dc65110f2693a4a7f088fbc6a3a12b6dfb013",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDdRz7yBYzOMcqB\n59H/sH6wFHdxstkN0XE7xRbhe7SFSa85aaNoPBC9b5Q3TjTAspNuxCM69z5blMsc\nwUJbl2+3IwPfUVvLhxqBsnxLDmND55EbEdNBmhhh2hLmlZEzRqiraDSMMS3Q02Hl\nolRgnhPbzBX1H7UCDAVVGtbECQMDtgewFEb7UdsaTfKJkJgB0ow2720sVUTW5yxP\njKT62iqBc3yxg1DXy513Ej2PTLhKl96bK1XF9ZfZTpffkcnYJakQZcAAe3Dw18uY\nQpc5EJR3rbeBfDoqvX6MonHGZ4WpEYP/x5A8BGhy1YcMlw0OJFgZdf3WFfOhn925\nwBQr4AeXAgMBAAECggEAV0ostZKk6g5QQZCukbwRLerU96BC6aWOkrJ8BTUkkFPx\n8KcQlCTlwaULhgmu27lWWaK79x3jloMK4OwH/lOt+UOx2l2g5ZgFR9aeG4mwdPAb\nmN8eREnCho9dV2L3JZAhJ4Ty/b7EwRUyEEFKIdcaJGHM46a/Y/BUBi+RO0IG02Y2\nfmFb2+yu/MRAVly2gNBGuiChHzmbXXbju1oGypgP61Cycl16D1PORrYCfBjwG/VC\nJVqNcGc54YY8twqwgmjck/S9XGa+Zf74Z8xocJYj3iLWGDyHoaveFv57VyDW7+iw\nFg20aZ3nIBteyHf2GgTWt5Vw4s4QHEgU4GO6Oy4syQKBgQD5/NYIJYXVp9PLJK3b\nUzGdxLo4sWA/bONtE8Q/mhy0o6hMfuHZXTj3yuHSXjetsX4x+dUsRFTxD7aLBn8q\n4vdMFZCbmVRoY5YU768Fyg3GClmGKhHrmTGKZBoLRjm34lT5yIJceR7pHneuyzd6\nllv1c4zmhjMUwFonapvIUjFHiwKBgQDimaXHo+odYE3rhQmVn3XzZzFwkWNdX8X3\nMrHtOBzxEKem39Hk1H7YyEdXGWbpBVtTEbgL/Q+fOYbMXMl35xi6Jp3gDpYyYYj8\nMZCBh+Yxz+XPshzYAhv5Cpzf7LHWmgMh3qXzjXswySM5pP3K8yyEtQ8o/q3lH/Nx\nkFdlJCwhpQKBgG/MN/fquADGDnzSCYKFoTHaciG6ib2zt73nUiPTizTp3/Fd6Skp\nfLmsnPNUuXfPYg19mm0ynf40tcFVBXgriscW+dXsa4hHyS3RxydCpohDxqeultcT\naslmXRNfs55d9PzERDCQ5lcBDis4rLYBGl0Z8RCDQcLtBySLk+GxiGJjAoGADqHt\nWp7zF0KIxZSpscfCTh1zy9kXmYf9uKDFbJQbClYQ/W2mmChAqK8GLFGvm4yFATA7\nukp1H8sPMVMsj1mU9zBXMYi/mjFCL0bkFfk4nC7YoDjYM/qu474Ts0INmdYILb+6\n56dTNStH4wkMenaJgWhPuk333LvbdJHlktprHyECgYEAzCB3gA16wZjVv9zLxpa7\nSb9l9TWFzHF/LzuSkjtjU4VRQ+QOMtyPC9OAmJ8x/DZ2jiQXcAH0zTSNsg2WWMC9\nSOYCZWID1TEQpaJw1/FKXeqCNM24tsWB+0pXSK5oEXz4lQkKkOBTt9HAmFFFsxLj\ngoPV9JTds4HIJIYeD3OmPhI=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@khushidua.iam.gserviceaccount.com",
      "client_id": "104089601298762472461",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40khushidua.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];
    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    //get the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  sendGlobalNotification(String title, String description) async {
    // _notificationController.setLoading(true);
    final String serverKey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        "https://fcm.googleapis.com/v1/projects/khushidua/messages:send";

    for (var user in _userController.allUsers) {
      Map<String, dynamic> message = {
        "message": {
          "token": user.fcmToken,
          "notification": {"title": title, "body": description},
          "data": {"notificationId": "ABC"}
        }
      };

      final http.Response response = await http.post(
          Uri.parse(endpointFirebaseCloudMessaging),
          headers: <String, String>{
            "Content-Type": "application/json",
            "Authorization": "Bearer $serverKey"
          },
          body: jsonEncode(message));

      if (response.statusCode != 200) {
        CustomSnackbar.show(
            "Failed".tr, "Failed to send notification to ${user.name}",
            isSuccess: false);
      } else if (response.statusCode == 200) {}
    }
    String id = notificationRef.doc().id;
    Map<String, dynamic> map = {
      "id": id,
      "title": title,
      "message": description,
      "createdAt": DateTime.now(),
      "sentTo": null
    };
    await notificationRef.doc(id).set(map);

    CustomSnackbar.show("Sent".tr, "Global Notification sent".tr,
        isSuccess: true);
  }

  sendIndividualNotification(UserModel user, String title, String msg) async {
    final String serverKey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        "https://fcm.googleapis.com/v1/projects/khushidua/messages:send";

    Map<String, dynamic> message = {
      "message": {
        "token": user.fcmToken,
        "notification": {"title": title, "body": msg},
        "data": {"notificationId": "ABC"}
      }
    };
    final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization": "Bearer $serverKey"
        },
        body: jsonEncode(message));

    if (response.statusCode != 200) {
      // CustomSnackbar.show("Failed".tr, "Failed to send notification to ${user.name}", isSuccess: false);
    } else if (response.statusCode == 200) {}

    String id = notificationRef.doc().id;
    Map<String, dynamic> map = {
      "id": id,
      "title": title,
      "message": msg,
      "createdAt": DateTime.now(),
      "sentTo": user.id
    };
    await notificationRef.doc(id).set(map);
  }
}
