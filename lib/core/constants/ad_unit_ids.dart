import 'package:flutter/foundation.dart';

/// Central AdMob ad-unit IDs.
abstract final class AdUnitIds {
  /// DEVELOPMENT: true
  /// PLAY STORE / APP STORE: false
  static const bool useTestAds = true;

  // ---------------- Android test IDs ----------------

  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _androidTestInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _androidTestAppOpen =
      'ca-app-pub-3940256099942544/9257395921';

  static const String _androidTestNative =
      'ca-app-pub-3940256099942544/2247696110';

  // ---------------- iOS test IDs ----------------

  static const String _iosTestBanner =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _iosTestInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _iosTestAppOpen =
      'ca-app-pub-3940256099942544/5575463023';

  static const String _iosTestNative =
      'ca-app-pub-3940256099942544/3986624511';

  // ---------------- Android production IDs ----------------
  // Replace these with your actual AdMob ad-unit IDs.

  static const String _androidProductionBanner =
      'YOUR_ANDROID_BANNER_AD_UNIT_ID';

  static const String _androidProductionInterstitial =
      'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';

  static const String _androidProductionAppOpen =
      'YOUR_ANDROID_APP_OPEN_AD_UNIT_ID';

  static const String _androidProductionNative =
      'YOUR_ANDROID_NATIVE_AD_UNIT_ID';

  // ---------------- iOS production IDs ----------------
  // Replace these with your actual AdMob ad-unit IDs.

  static const String _iosProductionBanner =
      'YOUR_IOS_BANNER_AD_UNIT_ID';

  static const String _iosProductionInterstitial =
      'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';

  static const String _iosProductionAppOpen =
      'YOUR_IOS_APP_OPEN_AD_UNIT_ID';

  static const String _iosProductionNative =
      'YOUR_IOS_NATIVE_AD_UNIT_ID';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner {
    if (useTestAds) {
      return _isIOS ? _iosTestBanner : _androidTestBanner;
    }

    return _isIOS
        ? _iosProductionBanner
        : _androidProductionBanner;
  }

  static String get interstitial {
    if (useTestAds) {
      return _isIOS
          ? _iosTestInterstitial
          : _androidTestInterstitial;
    }

    return _isIOS
        ? _iosProductionInterstitial
        : _androidProductionInterstitial;
  }

  static String get appOpen {
    if (useTestAds) {
      return _isIOS ? _iosTestAppOpen : _androidTestAppOpen;
    }

    return _isIOS
        ? _iosProductionAppOpen
        : _androidProductionAppOpen;
  }

  static String get native {
    if (useTestAds) {
      return _isIOS ? _iosTestNative : _androidTestNative;
    }

    return _isIOS
        ? _iosProductionNative
        : _androidProductionNative;
  }
}