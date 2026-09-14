import 'package:get/get.dart';

import '../models/homeBannerModel.dart';
import '../services/homeBannerService.dart';

/// Holds the admin-authored home banner, kept live by a Firestore listener.
class HomeBannerController extends GetxController {
  HomeBannerModel _banner = HomeBannerModel.empty();
  HomeBannerModel get banner => _banner;

  @override
  void onInit() {
    super.onInit();
    HomeBannerService().listen();
  }

  void setBanner(HomeBannerModel banner) {
    _banner = banner;
    update();
  }
}
