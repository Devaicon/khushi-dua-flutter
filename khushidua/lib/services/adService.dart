import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Starts AdMob only when an ad may be shown, configured for the audience of
/// the selected age group (0 little kids, 1 older kids, 2 grown ups).
///
/// Little kids never see ads, so AdMob is not even started for them: the SDK
/// makes no requests until [prepare] runs. Older kids are children too, so
/// their ads are child-directed (non-personalised) and G-rated.
abstract final class AdService {
  static Future<void>? _initialised;
  static int? _configuredFor;

  static bool allowsAds(int ageGroup) => ageGroup != 0;

  /// Configures and, the first time, starts AdMob for [ageGroup]. Must only be
  /// called for a group that [allowsAds].
  static Future<void> prepare(int ageGroup) async {
    assert(allowsAds(ageGroup));
    if (_configuredFor != ageGroup) {
      // Set before initialising, so no request ever goes out untagged.
      await MobileAds.instance.updateRequestConfiguration(
        ageGroup == 1
            ? RequestConfiguration(
                ageRestrictedTreatment: AgeRestrictedTreatment.child,
                maxAdContentRating: MaxAdContentRating.g,
              )
            : RequestConfiguration(
                ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
                maxAdContentRating: MaxAdContentRating.unspecified,
              ),
      );
      _configuredFor = ageGroup;
    }
    await (_initialised ??= MobileAds.instance
        .initialize()
        .then((status) {
          debugPrint('AdMob initialized: ${status.adapterStatuses}');
        })
        .catchError((Object e) {
          debugPrint('AdMob initialization failed: $e');
          _initialised = null;
        }));
  }
}
