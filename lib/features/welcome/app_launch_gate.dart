import 'package:flutter/material.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../permission/permission_required_screen.dart';
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
///  - Previously completed,
///    but something was      -> skip [WelcomeScreen] and go straight into
///    revoked afterwards        [PermissionRequiredScreen] so the user can
///                               re-grant just what's missing.
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

class _AppLaunchGateState extends State<AppLaunchGate> {
  bool _checking = true;

  /// null  -> still checking
  /// 0     -> go to HomeScreen (all required permissions granted)
  /// 1     -> go to PermissionRequiredScreen (onboarding was completed
  ///          before, but a required permission is missing/revoked now)
  /// 2     -> go to WelcomeScreen (first run / fresh install)
  int? _destination;

  @override
  void initState() {
    super.initState();

    // Fire-and-forget: never awaited, never blocks navigation decisions.
    ConnectivityService.instance.start();
    DeviceRegistrationService.registerOnLaunch();

    _decide();
  }

  Future<void> _decide() async {
    final granted = await PermissionFlowService.allRequiredGranted();

    if (!mounted) return;

    if (granted) {
      setState(() {
        _destination = 0;
        _checking = false;
      });
      return;
    }

    // Not all required permissions are granted. Figure out whether this
    // is a brand-new install (never asked yet) or a returning user who
    // revoked a permission after finishing onboarding once.
    final hasOnboarded = await PermissionFlowService.hasCompletedOnboarding();

    if (!mounted) return;

    setState(() {
      _destination = hasOnboarded ? 1 : 2;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _destination == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_destination) {
      case 0:
        return const HomeScreen();
      case 1:
        return const PermissionRequiredScreen();
      case 2:
      default:
        return const WelcomeScreen();
    }
  }
}