import 'package:get/get.dart';

import '../models/homeBannerModel.dart';
import '../services/homeBannerService.dart';

class HomeBannerController extends GetxController {
  HomeBannerModel _banner = HomeBannerModel.empty();
  HomeBannerModel get banner => _banner;

  bool _loading = false;
  bool get loading => _loading;

  /// True once the document has been fetched, so the form does not overwrite
  /// its controllers with empty values while the read is still in flight.
  bool _loaded = false;
  bool get loaded => _loaded;

  void setLoading(bool value) {
    _loading = value;
    update();
  }

  void setBanner(HomeBannerModel banner) {
    _banner = banner;
    _loaded = true;
    update();
  }

  Future<void> getBanner() => HomeBannerService().getBanner();

  Future<bool> saveBanner(HomeBannerModel banner, {dynamic imageFile}) =>
      HomeBannerService().saveBanner(banner, imageFile: imageFile);
}
