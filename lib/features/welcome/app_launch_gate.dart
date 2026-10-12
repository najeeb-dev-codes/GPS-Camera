import 'package:flutter/material.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../home/home_screen.dart';
import '../splash/app_splash_screen.dart';
import '../permission/permission_screen.dart';
import 'welocme_screen.dart';

/// App entry widget — use this as `home:` in `MaterialApp` instead of
/// [WelcomeScreen] or [HomeScreen] directly.
///
/// On every cold start it silently checks whether every required
/// permission (Camera, Precise Location, Photos & Media) is still granted:
///
///  - All granted            -> go straight to [HomeScreen].
///  - Nothing has ever run   -> show [WelcomeScreen] (first install, or a
///                              fresh install after uninstalling — the OS
///                              resets permission state, so this looks
///                              identical to a first-time run).
///  - Permission flow was    -> skip [WelcomeScreen] and go straight into
///    entered before, but       [PermissionScreen] so the user can
///    access is missing         re-grant just what's missing.
///
/// It also kicks off two app-wide, fire-and-forget background jobs that
/// have nothing to do with which screen gets shown:
///  - [ConnectivityService.start] — begins watching for connectivity so
///    any pending offline work (device registration, photo sync, ...)
///    retries automatically the moment the device comes back online.
///  - [DeviceRegistrationService.registerOnLaunch] — the one online-only
///    call in this otherwise offline-first app; queues itself silently
///    if there's no connection yet, so it never blocks or delays
///    navigation below.
class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({super.key});

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate>
    with WidgetsBindingObserver {
  bool _checking = true;

  /// null  -> still checking
  /// 0     -> go to HomeScreen (all required permissions granted)
  /// 1     -> go to PermissionScreen with only missing permission cards
  ///          before, but a required permission is missing/revoked now)
  /// 2     -> go to WelcomeScreen (first run / fresh install)
  int? _destination;
  bool _deciding = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Fire-and-forget: never awaited, never blocks navigation decisions.
    ConnectivityService.instance.start();
    DeviceRegistrationService.registerOnLaunch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Open the preloaded launch app-open ad on the very first frame.
      AdService.instance.showAppOpenIfReady();
      _decide();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
        _decide(showLoading: false);
      });
    }
  }

  Future<void> _decide({bool showLoading = true}) async {
    if (_deciding) return;
    _deciding = true;

    if (showLoading && mounted) {
      setState(() => _checking = true);
    }

    final granted = await PermissionFlowService.allRequiredGranted();

    if (!mounted) {
      _deciding = false;
      return;
    }

    if (granted) {
      // While the missing-permission screen is active, let that screen route
      // through PermissionsEnabledScreen after returning from App Settings.
      // Switching this gate directly to Home would skip the required success
      // screen.
      if (!showLoading && _destination == 1) {
        _deciding = false;
        return;
      }

      setState(() {
        _destination = 0;
        _checking = false;
      });
      _deciding = false;
      return;
    }

    // Not all required permissions are granted. Figure out whether this
    // is a brand-new install (never asked yet) or a user who already entered
    // onboarding and still has a missing/revoked required permission.
    final hasEnteredFlow =
        await PermissionFlowService.hasEnteredPermissionFlow();

    if (!mounted) {
      _deciding = false;
      return;
    }

    setState(() {
      _destination = hasEnteredFlow ? 1 : 2;
      _checking = false;
    });
    _deciding = false;
  }

  @override
  Widget build(BuildContext context) {
    // The launch app-open ad always comes first: keep the loading screen (no
    // Home / Welcome / "Get Started" button) until the ad has been shown and
    // closed, or failed / timed out / the device is offline.
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.launchAdFinished,
      builder: (context, launchAdFinished, _) {
        if (!launchAdFinished) {
          // Keep the branded splash visible while the launch ad is loading
          // or being displayed; never show an empty white screen in between.
          return const AppSplashScreen(
            nextScreen: SizedBox.shrink(),
            autoTransition: false,
          );
        }

        if (_checking || _destination == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        switch (_destination) {
          case 0:
            return const HomeScreen();
          case 1:
            return const PermissionScreen(showOnlyMissing: true);
          case 2:
          default:
            return const WelcomeScreen();
        }
      },
    );
  }
}