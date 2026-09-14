import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/firebaseRef.dart';
import '../controllers/homeBannerController.dart';
import '../models/homeBannerModel.dart';

/// Streams `SystemConfiguration/HomeBanner` so an admin edit reaches every
/// running app without a restart.
class HomeBannerService {
  void listen() {
    sysConfigRef
        .doc(HomeBannerModel.docId)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            Get.find<HomeBannerController>().setBanner(
              data == null
                  ? HomeBannerModel.empty()
                  : HomeBannerModel.fromMap(data),
            );
          },
          // Unlike the other listeners in this app, report failures instead of
          // silently rendering nothing — a denied read looked like "no data"
          // during the rules outage and cost a lot of time to diagnose.
          onError: (Object e) {
            debugPrint('🏠 HomeBannerService: listen failed: $e');
            Get.find<HomeBannerController>().setBanner(
              HomeBannerModel.empty(),
            );
          },
        );
  }
}
