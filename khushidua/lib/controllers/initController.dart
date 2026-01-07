import 'package:get/get.dart';
import 'package:khushidua/controllers/categoryController.dart';
import 'package:khushidua/controllers/duaController.dart';
import 'package:khushidua/controllers/themeController.dart';
import 'package:khushidua/controllers/userController.dart';
import 'package:khushidua/services/audioDownloadService.dart';

import 'notificationController.dart';

class InitControllers extends Bindings {
  @override
  void dependencies() {
    Get.put(UserController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(CategoryController(), permanent: true);
    Get.put(DuaController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(AudioDownloadService(), permanent: true);
  }
}
