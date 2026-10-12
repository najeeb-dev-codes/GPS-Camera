import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/constants/ad_unit_ids.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/connectivity_service.dart';

/// Responsive AdMob native-ad placement.
///
/// The ad is owned by this widget because a [NativeAd] must remain alive only
/// while its [AdWidget] is in the widget tree. Offline and failed ads collapse
/// completely so navigation remains usable.
class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({
    super.key,
    this.reserveSpaceWhileLoading = false,
    this.minimumHeight = 90,
    this.maximumHeight = 200,
    this.maximumWidth = 400,
    this.screenHeightFraction,
    this.fillAvailableWidth = false,
  })  : assert(minimumHeight > 0),
        assert(maximumHeight >= minimumHeight),
        assert(maximumWidth > 0),
        assert(
          screenHeightFraction == null ||
              (screenHeightFraction > 0 && screenHeightFraction <= 1),
        );

  final bool reserveSpaceWhileLoading;
  final double minimumHeight;
  final double maximumHeight;
  final double maximumWidth;

  /// When supplied, the native-ad height is calculated from the device's
  /// current logical screen height and constrained to the safe height range.
  final double? screenHeightFraction;

  /// Allows a placement to occupy all horizontal space offered by its parent.
  final bool fillAvailableWidth;

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  NativeAd? _nativeAd;
  StreamSubscription<bool>? _internetSubscription;
  bool? _hasInternet =
      ConnectivityService.instance.lastKnownInternetAccess;
  bool _isLoading = false;
  bool _loadScheduled = false;
  bool _loadFailed = false;
  int _requestGeneration = 0;
  int? _themeSignature;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.start();
    _internetSubscription =
        ConnectivityService.instance.onInternetStatusChanged.listen(
      _handleInternetStatus,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final colorScheme = Theme.of(context).colorScheme;
    final nextSignature = Object.hash(
      colorScheme.primary,
      colorScheme.onPrimary,
      colorScheme.surface,
      colorScheme.onSurface,
    );

    if (_themeSignature != null && _themeSignature != nextSignature) {
      _requestGeneration++;
      _nativeAd?.dispose();
      _nativeAd = null;
      _isLoading = false;
      _loadFailed = false;
    }
    _themeSignature = nextSignature;
    _scheduleLoad();
  }

  void _handleInternetStatus(bool hasInternet) {
    if (!mounted || _hasInternet == hasInternet) return;

    _hasInternet = hasInternet;
    if (!hasInternet) {
      _requestGeneration++;
      _nativeAd?.dispose();
      _nativeAd = null;
      _isLoading = false;
      _loadFailed = true;
    } else {
      _loadFailed = false;
      _scheduleLoad();
    }
    setState(() {});
  }

  void _scheduleLoad() {
    if (_loadScheduled ||
        _isLoading ||
        _nativeAd != null ||
        _hasInternet != true) {
      return;
    }

    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (mounted) _loadAd();
    });
  }

  void _loadAd() {
    if (_hasInternet != true ||
        !AdService.instance.isInitialized ||
        _isLoading ||
        _nativeAd != null) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final generation = ++_requestGeneration;
    _isLoading = true;
    _loadFailed = false;

    late final NativeAd candidate;
    candidate = NativeAd(
      adUnitId: AdUnitIds.native,
      request: const AdRequest(),
      factoryId: 'gpsMarkHomeNative',
      customOptions: <String, Object>{
        'backgroundColor': colorScheme.surface.value,
        'textColor': colorScheme.onSurface.value,
        'secondaryTextColor': colorScheme.onSurfaceVariant.value,
        'primaryColor': colorScheme.primary.value,
      },
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted ||
              generation != _requestGeneration ||
              _hasInternet != true) {
            candidate.dispose();
            return;
          }

          setState(() {
            _nativeAd = candidate;
            _isLoading = false;
            _loadFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(
            'Native ad failed to load: ${error.code} - ${error.message}',
          );

          if (!mounted || generation != _requestGeneration) return;
          setState(() {
            _isLoading = false;
            _loadFailed = true;
          });
        },
      ),
    )..load();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _requestGeneration++;
    _internetSubscription?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_hasInternet != true || _loadFailed) {
          return const SizedBox.shrink();
        }

        _scheduleLoad();

        final screenSize = MediaQuery.sizeOf(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenSize.width;
        final adWidth = widget.fillAvailableWidth
            ? availableWidth
            : math.min(availableWidth, widget.maximumWidth);

        final requestedHeight = widget.screenHeightFraction != null
            ? screenSize.height * widget.screenHeightFraction!
            : adWidth * 0.30;
        final adHeight = requestedHeight
            .clamp(widget.minimumHeight, widget.maximumHeight)
            .toDouble();
        final ad = _nativeAd;

        if (ad == null) {
          if (!widget.reserveSpaceWhileLoading) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            width: double.infinity,
            height: adHeight,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Do not clip, transform, or overflow a native platform view. The
        // complete Android NativeAdView must remain inside these bounds so all
        // registered advertiser assets pass AdMob native-ad validation.
        return SizedBox(
          width: double.infinity,
          height: adHeight,
          child: Center(
            child: SizedBox(
              width: adWidth,
              height: adHeight,
              child: AdWidget(ad: ad),
            ),
          ),
        );
      },
    );
  }
}
