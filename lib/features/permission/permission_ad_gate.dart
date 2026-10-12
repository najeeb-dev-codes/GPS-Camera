import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/widgets/widgets.dart';

/// Displays the permission-flow ad before releasing the next action.
///
/// A short delay after [AppAdLoadState.loaded] gives Flutter one frame to
/// paint the ad before an Android/iOS permission dialog covers the page.
/// Failed or unusually slow ad requests release the flow so onboarding can
/// never become blocked by connectivity or AdMob availability.
class PermissionAdGate extends StatefulWidget {
  const PermissionAdGate({
    super.key,
    required this.onReady,
    this.timeout = const Duration(seconds: 10),
    this.visibleBeforeActionDelay = const Duration(milliseconds: 250),
  });

  final VoidCallback onReady;
  final Duration timeout;
  final Duration visibleBeforeActionDelay;

  @override
  State<PermissionAdGate> createState() => _PermissionAdGateState();
}

class _PermissionAdGateState extends State<PermissionAdGate> {
  Timer? _timeoutTimer;
  Timer? _releaseTimer;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(widget.timeout, () => _release(Duration.zero));
  }

  void _handleLoadState(AppAdLoadState state) {
    if (state == AppAdLoadState.loaded) {
      _release(widget.visibleBeforeActionDelay);
      return;
    }

    if (state == AppAdLoadState.failed) {
      _release(Duration.zero);
    }
  }

  void _release(Duration delay) {
    if (_released) return;
    _released = true;
    _timeoutTimer?.cancel();

    _releaseTimer = Timer(delay, () {
      if (mounted) widget.onReady();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdBannerWidget(
      format: AdDisplayFormat.mediumRectangle,
      reserveSpaceWhileLoading: true,
      onLoadStateChanged: _handleLoadState,
    );
  }
}
