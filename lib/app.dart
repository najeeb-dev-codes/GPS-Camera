

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/welcome/app_launch_gate.dart';

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
class GPSCameraApp extends StatelessWidget {
  const GPSCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Camera App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppLaunchGate(),
    );
  }
}