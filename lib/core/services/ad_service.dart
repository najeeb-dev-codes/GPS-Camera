import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_unit_ids.dart';
import 'connectivity_service.dart';

/// Centralized lifecycle for banners, interstitials and app-open ads.
///
/// Ads are always optional. A missing connection, failed request, or failed
/// presentation completes immediately and never blocks the photo workflow.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  final Map<String, BannerAd> _readyBanners = <String, BannerAd>{};
  final Map<String, Future<BannerAd?>> _preloadingBanners =
      <String, Future<BannerAd?>>{};
  final Map<int, AdSize> _adaptiveSizes = <int, AdSize>{};
  bool _initialized = false;
  bool _disposed = false;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _isLoadingAppOpen = false;
  bool _isShowingAppOpen = false;
  bool _showAppOpenWhenLoaded = false;
  bool _appIsForeground = true;
  bool _fullScreenAdsBlocked = false;
  DateTime? _appOpenLoadedAt;
  DateTime? _lastAppOpenShownAt;
  StreamSubscription<bool>? _internetSubscription;
  bool _internetAvailable = false;

  /// The app-open ad is a launch ad: it is offered once per app start, and
  /// only while the launch is still fresh. After it is shown, fails, or the
  /// window expires, it is never shown again (no resume / post-interstitial
  /// app-open ads).
  bool _launchAppOpenPending = true;
  Timer? _launchAppOpenTimer;

  /// Longest the app waits at launch for the app-open ad to appear. If the ad
  /// is not ready in time (slow network, no fill) the app continues normally.
  static const Duration launchAdMaxWait = Duration(seconds: 10);

  /// `false` while the launch app-open ad is still pending (loading/showing).
  /// Becomes `true` once it was shown and closed, failed, timed out, or the
  /// device is offline. [AppLaunchGate] keeps the app on its loading screen
  /// until this is `true`, so the ad always comes first.
  final ValueNotifier<bool> launchAdFinished = ValueNotifier<bool>(false);

  /// Longest `initialize()` (awaited in main() before runApp) waits for the
  /// launch app-open ad to load. The native splash stays on screen during this
  /// time, so the ad can be shown on the very first frame with no loader.
  static const Duration launchAdPreloadWait = Duration(seconds: 4);
  final Completer<void> _launchAppOpenReady = Completer<void>();

  void _finishLaunchAppOpen() {
    _launchAppOpenPending = false;
    _showAppOpenWhenLoaded = false;
    _launchAppOpenTimer?.cancel();
    _launchAppOpenTimer = null;
    if (!_launchAppOpenReady.isCompleted) _launchAppOpenReady.complete();
    if (!launchAdFinished.value) launchAdFinished.value = true;
  }

  static const Duration _appOpenMaxAge = Duration(hours: 4);
  static const Duration _appOpenMinimumInterval = Duration(seconds: 30);

  bool get isInitialized => _initialized;
  bool get isAppOpenReady => _hasFreshAppOpenAd;

  /// Prevents app-open/interstitial ads from covering critical app-wide UI
  /// such as the force-update check and dialog. Banner loading is unaffected.
  void setFullScreenAdsBlocked(bool blocked) {
    if (_fullScreenAdsBlocked == blocked) return;
    _fullScreenAdsBlocked = blocked;

    if (blocked) {
      _showAppOpenWhenLoaded = false;
      return;
    }

    // Once the launch/update gate is cleared, request an app-open ad.
    // If one is not ready yet, showAppOpenIfReady() loads it asynchronously.
    if (_appIsForeground) {
      showAppOpenIfReady();
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();
      _disposed = false;
      _initialized = true;

      ConnectivityService.instance.start();
      _internetSubscription =
          ConnectivityService.instance.onInternetStatusChanged.listen(
        _handleInternetStatus,
      );

      final knownStatus =
          ConnectivityService.instance.lastKnownInternetAccess;
      if (knownStatus != null) {
        _handleInternetStatus(knownStatus);
      } else {
        unawaited(ConnectivityService.instance.hasInternetAccess());
      }

      // Preload the launch app-open ad BEFORE the first screen is drawn, so it
      // can open immediately instead of after a loading screen.
      await _launchAppOpenReady.future.timeout(
        launchAdPreloadWait,
        onTimeout: () {},
      );

      // From here on the UI is up; cap how long the launch can still wait.
      if (_launchAppOpenPending) {
        _launchAppOpenTimer ??= Timer(launchAdMaxWait, _finishLaunchAppOpen);
      }
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
      _finishLaunchAppOpen();
    }
  }

  void _handleInternetStatus(bool hasInternet) {
    if (_disposed) return;
    // Offline at launch: no ad can be shown, let the user into the app.
    if (!hasInternet && _launchAppOpenPending) _finishLaunchAppOpen();
    if (_internetAvailable == hasInternet) return;
    _internetAvailable = hasInternet;

    if (!hasInternet) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      for (final ad in _readyBanners.values) {
        ad.dispose();
      }
      _readyBanners.clear();
      return;
    }

    _loadInterstitial();
    _loadAppOpen();
    if (_appIsForeground) {
      showAppOpenIfReady();
    }
    _preloadBanner(AdSize.mediumRectangle);
    _preloadBanner(AdSize.largeBanner);
    unawaited(_preloadInitialAdaptiveBanner());
  }

  String _bannerKey(AdSize size) => '${size.width}x${size.height}';

  Future<void> _preloadInitialAdaptiveBanner() async {
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isEmpty) return;

      final view = views.first;
      final logicalWidth =
          (view.physicalSize.width / view.devicePixelRatio).floor();
      if (logicalWidth <= 0) return;

      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        logicalWidth,
      );
      if (size != null) {
        _adaptiveSizes[logicalWidth] = size;
        _preloadBanner(size);
      }
    } catch (error) {
      debugPrint('Initial banner preload failed: $error');
    }
  }

  Future<AdSize?> adaptiveBannerSize(int width) async {
    final cached = _adaptiveSizes[width];
    if (cached != null) return cached;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size != null) _adaptiveSizes[width] = size;
    return size;
  }

  Future<BannerAd?> _createBanner(AdSize size) {
    if (!_internetAvailable) return Future<BannerAd?>.value(null);

    final completion = Completer<BannerAd?>();
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!_internetAvailable || _disposed) {
            ad.dispose();
            completion.complete(null);
            return;
          }
          completion.complete(ad);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint('Banner ad failed to load: $error');
          completion.complete(null);
        },
      ),
    );
    ad.load();
    return completion.future;
  }

  void _preloadBanner(AdSize size) {
    if (!_initialized || !_internetAvailable) return;

    final key = _bannerKey(size);
    if (_readyBanners.containsKey(key) ||
        _preloadingBanners.containsKey(key)) {
      return;
    }

    final loading = _createBanner(size);
    _preloadingBanners[key] = loading;
    loading.then((ad) {
      if (!identical(_preloadingBanners[key], loading)) {
        if (_disposed) ad?.dispose();
        return;
      }
      _preloadingBanners.remove(key);
      if (ad != null && _internetAvailable && !_disposed) {
        _readyBanners[key] = ad;
      } else {
        ad?.dispose();
      }
    });
  }

  /// Returns a ready cached banner when possible and immediately replenishes
  /// the cache for the next screen.
  Future<BannerAd?> acquireBanner(AdSize size) async {
    if (!_initialized || !_internetAvailable) return null;

    final key = _bannerKey(size);
    final ready = _readyBanners.remove(key);
    if (ready != null) {
      _preloadBanner(size);
      return ready;
    }

    // Removing claims this preloaded ad for only this widget. A concurrent
    // screen will load/claim a different BannerAd instance.
    final preloading = _preloadingBanners.remove(key);
    if (preloading != null) {
      final ad = await preloading;
      if (_disposed) {
        ad?.dispose();
        return null;
      }
      _preloadBanner(size);
      return ad;
    }

    final ad = await _createBanner(size);
    _preloadBanner(size);
    return ad;
  }

  void _loadInterstitial() {
    if (!_initialized ||
        !_internetAvailable ||
        _isLoadingInterstitial ||
        _interstitialAd != null ||
        _isShowingInterstitial) {
      return;
    }

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          if (!_internetAvailable || _disposed) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  bool get _hasFreshAppOpenAd {
    final loadedAt = _appOpenLoadedAt;
    if (_appOpenAd == null || loadedAt == null) return false;

    return DateTime.now().difference(loadedAt) < _appOpenMaxAge;
  }

  void _loadAppOpen() {
    if (!_initialized ||
        !_internetAvailable ||
        _disposed ||
        _isLoadingAppOpen ||
        _appOpenAd != null ||
        _isShowingAppOpen) {
      return;
    }

    _isLoadingAppOpen = true;

    AppOpenAd.load(
      adUnitId: AdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpen = false;

          if (_disposed || !_internetAvailable) {
            ad.dispose();
            return;
          }

          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          debugPrint('App-open ad loaded successfully.');
          if (!_launchAppOpenReady.isCompleted) _launchAppOpenReady.complete();

          if (_showAppOpenWhenLoaded && _appIsForeground) {
            scheduleMicrotask(showAppOpenIfReady);
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpen = false;
          _finishLaunchAppOpen();
          debugPrint(
            'App-open ad failed to load: ${error.code} - ${error.message}',
          );
        },
      ),
    );
  }

  /// Shows a cached app-open ad when possible and never blocks navigation.
  ///
  /// A short interval prevents permission dialogs, the ad itself, or a quick
  /// app switch from immediately causing another full-screen ad.
  void showAppOpenIfReady() {
    // Launch-only: show the app-open ad when the app is opened, never on
    // resume or after an interstitial is dismissed.
    if (!_launchAppOpenPending) return;

    if (!_initialized ||
        _disposed ||
        !_appIsForeground ||
        _isShowingAppOpen ||
        _isShowingInterstitial) {
      return;
    }

    // NOTE: the launch app-open ad intentionally ignores
    // [_fullScreenAdsBlocked] (the version-check gate) so it opens first,
    // immediately. A force-update dialog still appears right after it closes.
    if (!_internetAvailable) {
      _showAppOpenWhenLoaded = true;
      return;
    }

    final lastShownAt = _lastAppOpenShownAt;
    if (lastShownAt != null &&
        DateTime.now().difference(lastShownAt) < _appOpenMinimumInterval) {
      return;
    }

    if (!_hasFreshAppOpenAd) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _showAppOpenWhenLoaded = true;
      _loadAppOpen();
      return;
    }

    final ad = _appOpenAd;
    if (ad == null) {
      _showAppOpenWhenLoaded = true;
      _loadAppOpen();
      return;
    }

    _showAppOpenWhenLoaded = false;
    _launchAppOpenPending = false;
    _launchAppOpenTimer?.cancel();
    _launchAppOpenTimer = null;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _isShowingAppOpen = true;
    _lastAppOpenShownAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('App-open ad displayed.');
      },
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingAppOpen = false;
        _finishLaunchAppOpen();
        debugPrint('App-open ad dismissed.');
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        _isShowingAppOpen = false;
        _finishLaunchAppOpen();
        debugPrint(
          'App-open ad failed to show: ${error.code} - ${error.message}',
        );
        _loadAppOpen();
      },
    );

    try {
      ad.show();
    } catch (error) {
      ad.dispose();
      _isShowingAppOpen = false;
      _finishLaunchAppOpen();
      debugPrint('App-open ad show error: $error');
      _loadAppOpen();
    }
  }

  void setAppForeground(bool isForeground) {
    _appIsForeground = isForeground;

    if (isForeground) {
      unawaited(ConnectivityService.instance.hasInternetAccess());
    }

    if (isForeground && !_fullScreenAdsBlocked) {
      showAppOpenIfReady();
    }
  }

  /// Shows the preloaded interstitial and completes when it has been dismissed.
  /// Returns immediately when no ad is ready.
  Future<void> showInterstitialIfReady() async {
    final ad = _interstitialAd;
    if (!_initialized ||
        !_internetAvailable ||
        _fullScreenAdsBlocked ||
        ad == null ||
        _isShowingInterstitial ||
        _isShowingAppOpen) {
      _loadInterstitial();
      return;
    }

    _interstitialAd = null;
    _isShowingInterstitial = true;
    final completion = Completer<void>();

    void finish() {
      if (!completion.isCompleted) completion.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingInterstitial = false;
        _loadInterstitial();
        finish();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        _isShowingInterstitial = false;
        debugPrint('Interstitial ad failed to show: $error');
        _loadInterstitial();
        finish();
      },
    );

    try {
      ad.show();
      await completion.future;
    } catch (error) {
      ad.dispose();
      _isShowingInterstitial = false;
      debugPrint('Interstitial ad show error: $error');
      _loadInterstitial();
      finish();
    }
  }

  void dispose() {
    _disposed = true;
    _internetSubscription?.cancel();
    _internetSubscription = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    for (final ad in _readyBanners.values) {
      ad.dispose();
    }
    _readyBanners.clear();
    _preloadingBanners.clear();
    _adaptiveSizes.clear();
  }
}