import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/services/connectivity_service.dart';

enum AdDisplayFormat {
  adaptiveBanner,
  standardBanner,
  largeBanner,
  mediumRectangle,
}

enum AppAdLoadState {
  loading,
  loaded,
  failed,
}

/// Reusable responsive AdMob slot.
///
/// Adaptive banners use the exact available layout width. Medium rectangle
/// placements use AdMob's 300x250 size and remain centered. Failed/offline ads
/// collapse to zero height so the surrounding feature remains fully usable.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    super.key,
    this.format = AdDisplayFormat.adaptiveBanner,
    this.reserveSpaceWhileLoading = false,
    this.slotHeight,
    this.decoration,
    this.onLoadStateChanged,
  });

  final AdDisplayFormat format;

  /// Keeps the requested ad area visible while AdMob is loading.
  final bool reserveSpaceWhileLoading;

  /// Optional placement height. It is applied only while the ad is online;
  /// offline placements still collapse completely.
  final double? slotHeight;

  final Decoration? decoration;

  /// Used only by screens that must react to the ad lifecycle, such as the
  /// first-run Get Started screen.
  final ValueChanged<AppAdLoadState>? onLoadStateChanged;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  int? _requestedWidth;
  int _requestGeneration = 0;
  bool _loadScheduled = false;
  AppAdLoadState? _loadState;
  StreamSubscription<bool>? _internetSubscription;
  bool? _hasInternet =
      ConnectivityService.instance.lastKnownInternetAccess;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.start();
    _internetSubscription =
        ConnectivityService.instance.onInternetStatusChanged.listen(
      _onInternetStatusChanged,
    );
    if (_hasInternet == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setLoadState(AppAdLoadState.failed);
      });
    }
  }

  void _onInternetStatusChanged(bool hasInternet) {
    if (!mounted || _hasInternet == hasInternet) return;

    _hasInternet = hasInternet;
    if (!hasInternet) {
      _requestGeneration++;
      _requestedWidth = null;
      final ad = _bannerAd;
      _bannerAd = null;
      ad?.dispose();
      _setLoadState(AppAdLoadState.failed);
    } else {
      _requestedWidth = null;
      _loadState = null;
    }
    setState(() {});
  }

  void _setLoadState(AppAdLoadState state) {
    if (_loadState == state) return;
    _loadState = state;
    widget.onLoadStateChanged?.call(state);
  }

  void _scheduleLoad(int availableWidth) {
    if (_requestedWidth == availableWidth || _loadScheduled) return;

    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (mounted) _loadBanner(availableWidth);
    });
  }

  Future<void> _loadBanner(int availableWidth) async {
    if (_hasInternet != true ||
        !AdService.instance.isInitialized ||
        availableWidth <= 0) {
      _setLoadState(AppAdLoadState.failed);
      return;
    }

    _setLoadState(AppAdLoadState.loading);
    final fixedSize = switch (widget.format) {
      AdDisplayFormat.standardBanner => AdSize.banner,
      AdDisplayFormat.largeBanner => AdSize.largeBanner,
      AdDisplayFormat.mediumRectangle => AdSize.mediumRectangle,
      AdDisplayFormat.adaptiveBanner => null,
    };
    _requestedWidth = availableWidth;
    final generation = ++_requestGeneration;
    final usableFixedSize =
        fixedSize != null && availableWidth >= fixedSize.width
            ? fixedSize
            : null;
    final AdSize? size = usableFixedSize ??
        await AdService.instance.adaptiveBannerSize(availableWidth);

    if (!mounted || generation != _requestGeneration) return;
    if (size == null) {
      _setLoadState(AppAdLoadState.failed);
      return;
    }

    final oldAd = _bannerAd;
    setState(() => _bannerAd = null);
    oldAd?.dispose();

    final ad = await AdService.instance.acquireBanner(size);
    if (ad == null) {
      if (mounted && generation == _requestGeneration) {
        _setLoadState(AppAdLoadState.failed);
      }
      return;
    }
    if (!mounted || generation != _requestGeneration) {
      ad.dispose();
      return;
    }
    setState(() => _bannerAd = ad);
    _setLoadState(AppAdLoadState.loaded);
  }

  @override
  void didUpdateWidget(covariant AdBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.format != widget.format) {
      _requestedWidth = null;
      _requestGeneration++;
      _bannerAd?.dispose();
      _bannerAd = null;
      _loadState = null;
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _internetSubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_hasInternet != true) return const SizedBox.shrink();

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.floor()
            : MediaQuery.sizeOf(context).width.floor();
        _scheduleLoad(availableWidth);

        final ad = _bannerAd;
        if (ad == null) {
          if (!widget.reserveSpaceWhileLoading ||
              _loadState == AppAdLoadState.failed) {
            return const SizedBox.shrink();
          }

          final reservedHeight = widget.slotHeight ?? switch (widget.format) {
            AdDisplayFormat.mediumRectangle =>
              availableWidth >= AdSize.mediumRectangle.width ? 250.0 : 50.0,
            AdDisplayFormat.standardBanner => 50.0,
            AdDisplayFormat.largeBanner => 100.0,
            AdDisplayFormat.adaptiveBanner => 50.0,
          };

          return Container(
            width: double.infinity,
            height: reservedHeight,
            decoration: widget.decoration,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: widget.slotHeight ?? ad.size.height.toDouble(),
          decoration: widget.decoration ??
              BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
          child: Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        );
      },
    );
  }
}
