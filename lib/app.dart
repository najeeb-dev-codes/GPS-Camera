import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'core/services/ad_service.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/firebase_monitoring_service.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/app_launch_gate.dart';
import 'features/splash/app_splash_screen.dart';
import 'shared/widgets/dialogs/force_update_dialog.dart';

/// Root widget. Wires the global theme and the app's entry point.
///
/// IMPORTANT: `home:` must be [AppLaunchGate], not [WelcomeScreen] or
/// [HomeScreen] directly.
///
/// [AppLaunchGate] is what decides, on every cold start, whether to show:
///   - HomeScreen                (all required permissions already granted)
///   - PermissionRequiredScreen  (onboarded before, but something got
///                                revoked in system Settings since)
///   - WelcomeScreen             (first install / fresh reinstall)
///
/// Pointing `home:` straight at WelcomeScreen (as before) skipped that
/// check entirely, so the app always opened on Welcome -> Permission ->
/// Enabled -> Home even when every permission was already granted.
///
/// From here on, WelcomeScreen's "Get Started" button and the rest of the
/// permission flow (PermissionScreen, PermissionsEnabledScreen,
/// PermissionRequiredScreen) all navigate themselves via
/// PermissionFlowService — nothing else needs to be wired up in this file.
class GPSMark extends StatefulWidget {
  const GPSMark({super.key});

  @override
  State<GPSMark> createState() => GPSMarkState();
}

class GPSMarkState extends State<GPSMark>
    with WidgetsBindingObserver {
  final AppUpdateService _updateService = AppUpdateService.instance;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Block app-open/interstitial ads until the launch version check finishes.
    // Banner/native ads are not affected.
    AdService.instance.setFullScreenAdsBlocked(true);
    _updateService.addListener(_handleUpdateStateChanged);


    _updateService.start();
  }

  void _handleUpdateStateChanged() {
    AdService.instance.setFullScreenAdsBlocked(
      _updateService.shouldBlockFullScreenAds,
    );

    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        AdService.instance.setAppForeground(false);
        break;
      case AppLifecycleState.resumed:
        AdService.instance.setAppForeground(true);
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;

        // Ignore short interruptions such as permission dialogs and the ad's
        // own activity. Show again only after a real background interval.
        if (backgroundedAt != null &&
            DateTime.now().difference(backgroundedAt) >=
                const Duration(seconds: 10)) {
          _updateService.checkAfterResume();
        }
        break;
      case AppLifecycleState.detached:
        AdService.instance.setAppForeground(false);
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateService.removeListener(_handleUpdateStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'GPS Mark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        navigatorKey: AppNavigator.rootNavigatorKey,
        navigatorObservers: FirebaseMonitoringService.navigatorObservers,
        home: const AppSplashScreen(
          nextScreen: AppLaunchGate(),
        ),
        builder: (context, child) => _AppVersionGate(
          updateService: _updateService,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// App-wide gate that checks the backend before online startup is exposed.
///
/// Offline users are allowed to continue. [AppUpdateService] listens for the
/// connection to return and performs the same check automatically. A backend
/// response reporting any available update replaces this gate with a
/// non-dismissible update barrier above every route in the application.
class _AppVersionGate extends StatelessWidget {
  const _AppVersionGate({
    required this.updateService,
    required this.child,
  });

  final AppUpdateService updateService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = updateService.state;


    // Do not block the normal app startup while the background version check
    // is running. If a force update is required, the barrier below is shown
    // as soon as the check completes.
    if (state == AppUpdateCheckState.idle ||
        state == AppUpdateCheckState.checking) {
      return child;
    }

    final updateInfo = updateService.updateInfo;
    if (updateService.requiresForceUpdate && updateInfo != null) {
      return PopScope(
        canPop: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            const ModalBarrier(
              dismissible: false,
              color: Colors.black,
            ),
            Center(
              child: ForceUpdateDialog(updateInfo: updateInfo),
            ),
          ],
        ),
      );
    }

    // waitingForInternet: allow offline use; the service checks again as soon
    // as verified internet access returns.
    // completed: current version is allowed by the backend.
    // failed: never lock users out because of a server/network error.
    return child;
  }
}
