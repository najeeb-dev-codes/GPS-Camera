import 'dart:async' show unawaited;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_navigator.dart';
import '../../features/permission/camera_access_screen.dart';
import '../../features/permission/location_access_screen.dart';
import '../../features/permission/notification_access_screen.dart';
import '../../features/permission/permission_page_route.dart';
import '../../features/permission/photos_media_access_screen.dart';
import '../../features/permission/permission_screen.dart';
import '../../features/permission/permissions_enabled_screen.dart';
import 'device_registration_service.dart';

/// Ordered steps used by the one-card-at-a-time permission flow
/// (Camera -> Location -> Photos -> Notifications).
enum PermissionStep { camera, location, photos, notifications }

/// Permissions managed from the Settings > Permissions screen.
enum ManagedAppPermission { camera, location, gallery, notifications }

/// Central place for everything related to runtime permissions:
/// checking status, requesting permissions, and deciding where the
/// permission flow should go next.
class PermissionFlowService {
  PermissionFlowService._();

  static const List<ManagedAppPermission> requiredPermissions =
      <ManagedAppPermission>[
    ManagedAppPermission.camera,
    ManagedAppPermission.location,
    ManagedAppPermission.gallery,
  ];

  static const List<ManagedAppPermission> onboardingPermissions =
      <ManagedAppPermission>[
    ...requiredPermissions,
    ManagedAppPermission.notifications,
  ];

  static const String _onboardedKey = 'permission_onboarding_completed';
  static const String _onboardingStartedKey =
      'permission_onboarding_started';

  // ---------------------------------------------------------------------
  // ONBOARDING COMPLETION FLAG
  // ---------------------------------------------------------------------
  //
  // Distinguishes "first install, never went through the permission
  // flow yet" from "went through it before, but a permission was later
  // revoked in system Settings". AppLaunchGate uses this to decide
  // whether to show WelcomeScreen (first case) or jump straight into
  // the missing-permission version of PermissionScreen (second case).
  //
  // NOTE: an app uninstall/reinstall clears app storage (and OS resets
  // permission grants too), so this flag naturally resets to "false"
  // on a fresh install — exactly matching the required behavior.

  /// Marks that the user has been through the permission flow at least
  /// once (i.e. reached PermissionsEnabledScreen, or otherwise finished
  /// "Allow & Continue" with a definitive result). Call this once,
  /// right when the user first reaches [PermissionsEnabledScreen].
  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingStartedKey, true);
    await prefs.setBool(_onboardedKey, true);
  }

  /// Records that the user has left Welcome and entered the permission flow.
  /// This lets a later cold start resume at Permission Required instead of
  /// showing Welcome again when onboarding was closed before every required
  /// permission had been granted.
  static Future<void> markOnboardingStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingStartedKey, true);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  /// Completes the first permission setup and opens the correct destination.
  ///
  /// The very first successful grant goes directly to Camera. Once that
  /// first setup has been completed, any later recovery after a permission
  /// was revoked goes to PermissionsEnabledScreen instead.
  static Future<void> completeRequiredPermissionFlow(
    BuildContext context,
  ) async {
    final alreadyCompleted = await hasCompletedOnboarding();

    if (!context.mounted) return;

    await markOnboardingCompleted();

    if (!context.mounted) return;

    if (!alreadyCompleted) {
      AppNavigator.goToCameraAfterPermissionOnboarding(context);
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      buildPermissionPageRoute<void>(
        const PermissionsEnabledScreen(),
      ),
      (route) => false,
    );
  }

  static Future<bool> hasEnteredPermissionFlow() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_onboardingStartedKey) ?? false) ||
        (prefs.getBool(_onboardedKey) ?? false);
  }

  // ---------------------------------------------------------------------
  // STATUS CHECKS
  // ---------------------------------------------------------------------

  static Future<bool> isCameraGranted() async {
    return (await Permission.camera.status).isGranted;
  }

  /// IMPORTANT: this must use the SAME permission type that is actually
  /// requested by LocationAccessScreen and PermissionScreen's
  /// "Allow & Continue" flow — Permission.locationWhenInUse — not the
  /// generic Permission.location. Checking a different permission type
  /// than what was requested/granted meant this could stay `false`
  /// forever even after the user granted location, which is why the app
  /// kept re-showing the permission flow on every relaunch instead of
  /// going straight to HomeScreen.
  static Future<bool> isLocationGranted() async {
    return (await Permission.locationWhenInUse.status).isGranted;
  }

  /// IMPORTANT: must check the SAME permission that
  /// PhotosMediaAccessScreen actually requests. On Android 13+ that's
  /// Permission.photos (READ_MEDIA_IMAGES/VIDEO); on Android 12 and below
  /// it's Permission.storage (READ_EXTERNAL_STORAGE) — permission_handler's
  /// own internal SDK-version detection for Permission.photos isn't
  /// reliable on every OEM build (MIUI in particular), which is why the
  /// request side resolves the permission explicitly via device_info_plus.
  /// Checking Permission.photos.status unconditionally here meant that
  /// even after a user manually granted storage access in system
  /// Settings on Android 12, this kept reporting `false` forever, so
  /// allRequiredGranted() never passed and Home was unreachable.
  static Future<bool> isPhotosGranted() async {
    final permission = await _resolvePhotoPermission();
    final status = await permission.status;
    // "Limited" access (iOS / Android 14+ partial photo selection) counts
    // as granted for our purposes.
    return status.isGranted || status.isLimited;
  }

  /// Resolves the correct "photos & media" permission for this exact
  /// device/OS combination. Mirrors the logic in
  /// PhotosMediaAccessScreen._resolvePhotoPermission — keep both in sync.
  static Future<Permission> _resolvePhotoPermission() async {
    if (!Platform.isAndroid) {
      return Permission.photos;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      return Permission.photos;
    }

    return Permission.storage;
  }

  static Future<bool> isNotificationGranted() async {
    return (await Permission.notification.status).isGranted;
  }

  /// Requests one permission through the operating system runtime-permission
  /// API and returns its refreshed granted state. This method never opens App
  /// Settings when a grant request is denied.
  static Future<bool> requestPermission(
    ManagedAppPermission permission,
  ) async {
    await (await _permissionFor(permission)).request();

    unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());

    return switch (permission) {
      ManagedAppPermission.camera => isCameraGranted(),
      ManagedAppPermission.location => isLocationGranted(),
      ManagedAppPermission.gallery => isPhotosGranted(),
      ManagedAppPermission.notifications => isNotificationGranted(),
    };
  }

  static Future<Permission> _permissionFor(
    ManagedAppPermission permission,
  ) async {
    switch (permission) {
      case ManagedAppPermission.camera:
        return Permission.camera;
      case ManagedAppPermission.location:
        return Permission.locationWhenInUse;
      case ManagedAppPermission.gallery:
        return _resolvePhotoPermission();
      case ManagedAppPermission.notifications:
        return Permission.notification;
    }
  }

  /// True after an earlier denial when Android recommends explaining why the
  /// permission is needed before showing the OS dialog again.
  static Future<bool> shouldShowRequestWarning(
    ManagedAppPermission permission,
  ) async {
    final platformPermission = await _permissionFor(permission);
    final status = await platformPermission.status;
    if (status.isGranted || status.isLimited || status.isPermanentlyDenied) {
      return false;
    }
    return platformPermission.shouldShowRequestRationale;
  }

  static Future<bool> isPermanentlyDenied(
    ManagedAppPermission permission,
  ) async {
    return (await (await _permissionFor(permission)).status)
        .isPermanentlyDenied;
  }

  static Future<List<ManagedAppPermission>> permanentlyDeniedPermissions(
    Iterable<ManagedAppPermission> permissions,
  ) async {
    final blocked = <ManagedAppPermission>[];
    for (final permission in permissions) {
      if (await isPermanentlyDenied(permission)) {
        blocked.add(permission);
      }
    }
    return blocked;
  }

  static Future<List<ManagedAppPermission>> permissionsNeedingWarning(
    Iterable<ManagedAppPermission> permissions,
  ) async {
    final warnings = <ManagedAppPermission>[];
    for (final permission in permissions) {
      if (await shouldShowRequestWarning(permission)) {
        warnings.add(permission);
      }
    }
    return warnings;
  }

  /// Mobile operating systems do not allow an app to revoke its own runtime
  /// permissions. Revocation must be completed by the user in system settings.
  static Future<bool> openSystemSettings() => openAppSettings();

  /// Camera, Location and Photos are required for the app to function.
  /// Notifications is recommended only and is NOT part of this check.
  static Future<bool> allRequiredGranted() async {
    final camera = await isCameraGranted();
    final location = await isLocationGranted();
    final photos = await isPhotosGranted();
    return camera && location && photos;
  }

  // ---------------------------------------------------------------------
  // REQUEST ALL (used by "Allow & Continue" on PermissionScreen)
  // ---------------------------------------------------------------------

  /// Requests Camera, Location, Photos and Notifications together.
  ///
  /// Used when the user taps "Allow & Continue" instead of granting
  /// each permission one by one. Permissions that are already granted are
  /// skipped by `permission_handler` automatically. Notification permission
  /// remains optional, but its OS prompt is included in this button's sequence.
  static Future<bool> requestAllRequired() async {
    final photoPermission = await _resolvePhotoPermission();

    await [
      Permission.camera,
      Permission.locationWhenInUse,
      photoPermission,
    ].request();

    // Notifications are optional for app entry, but Allow & Continue must
    // still request them when they have not been granted.
    if (!(await Permission.notification.status).isGranted) {
      await Permission.notification.request();
    }

    final granted = await allRequiredGranted();

    // Permission state just changed materially — send an updated
    // registration payload (fresh permissions map / lat-lng-eligibility)
    // rather than waiting for the next cold start. Fire-and-forget: this
    // must never block or fail the permission flow itself.
    unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());

    return granted;
  }

  /// Re-requests only the required permissions that are still missing.
  /// Used by Permission Required recovery so an optional notification denial
  /// is not requested again while the user is repairing required access.
  static Future<bool> requestMissingRequired() async {
    final photoPermission = await _resolvePhotoPermission();

    await [
      Permission.camera,
      Permission.locationWhenInUse,
      photoPermission,
    ].request();

    final granted = await allRequiredGranted();
    unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());
    return granted;
  }

  // ---------------------------------------------------------------------
  // ENTRY POINT (used by WelcomeScreen's "Get Started" button)
  // ---------------------------------------------------------------------

  /// Called when the user taps "Get Started" on [WelcomeScreen].
  ///
  /// Welcome always enters [PermissionScreen]. The launch gate is solely
  /// responsible for sending an already-configured user directly to Home.
  static Future<void> startFlow(BuildContext context) async {
    await markOnboardingStarted();

    if (!context.mounted) return;

    await Navigator.of(context).push<void>(
      buildPermissionPageRoute<void>(const PermissionScreen()),
    );
  }

  // ---------------------------------------------------------------------
  // STEP-BY-STEP NAVIGATION
  // (used by "Not Now" / granted callbacks inside each *_access_screen)
  // ---------------------------------------------------------------------

  /// Moves the one-at-a-time onboarding flow forward from [from] to the
  /// next step. After the last step (Notifications), checks whether every
  /// required permission ended up granted and routes to
  /// [PermissionsEnabledScreen] or the missing-permission center accordingly.
  static Future<void> advance(
    BuildContext context, {
    required PermissionStep from,
  }) async {
    Widget? next;

    switch (from) {
      case PermissionStep.camera:
        next = const LocationAccessScreen();
        break;
      case PermissionStep.location:
        next = const PhotosMediaAccessScreen();
        break;
      case PermissionStep.photos:
        next = const NotificationAccessScreen();
        break;
      case PermissionStep.notifications:
        next = null;
        break;
    }

    if (!context.mounted) return;

    if (next == null) {
      // Reached the end of the one-by-one chain (Camera -> Location ->
      // Photos -> Notifications). Decide where to land based on the
      // required permissions.
      final granted = await allRequiredGranted();

      // Permission state just settled for this onboarding pass — send an
      // updated registration payload with the real permissions/location
      // fields now available. Fire-and-forget, same reasoning as above.
      unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());

      if (!context.mounted) return;

      if (granted) {
        await completeRequiredPermissionFlow(context);
      } else {
        await Navigator.of(context).pushReplacement(
          buildPermissionPageRoute<void>(
            const PermissionScreen(showOnlyMissing: true),
          ),
        );
      }
      return;
    }

    await Navigator.of(context).pushReplacement(
      buildPermissionPageRoute<void>(next!),
    );
  }
}
