

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'camera_access_screen.dart';
import 'location_access_screen.dart';
import 'notification_access_screen.dart';
import 'permission_required_screen.dart';
import 'permissions_enabled_screen.dart';
import 'photos_media_access_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  static const String _description =
      'GeoStamp Camera needs the following permissions to work.';

  static const String _footnote = 'Location is added only when you capture.';

  bool _isLoading = true;

  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _photosGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check statuses when the user comes back from device Settings.
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final camera = await PermissionFlowService.isCameraGranted();
    final location = await PermissionFlowService.isLocationGranted();
    final photos = await PermissionFlowService.isPhotosGranted();
    final notifications = await PermissionFlowService.isNotificationGranted();

    if (!mounted) return;

    setState(() {
      _cameraGranted = camera;
      _locationGranted = location;
      _photosGranted = photos;
      _notificationGranted = notifications;
      _isLoading = false;
    });
  }

  int get _enabledCount => [
        _cameraGranted,
        _locationGranted,
        _photosGranted,
        _notificationGranted,
      ].where((granted) => granted).length;

  Future<void> _openPermission(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
    await _refreshStatuses();
  }

  /// Requests every permission back-to-back using the native OS dialogs,
  /// without navigating through the individual permission screens.
  ///
  /// Tapping "Allow & Continue" fires the system prompts one after another:
  /// Camera -> Location -> Photos -> Notifications. A permission already
  /// granted (or already permanently denied) is skipped without showing a
  /// dialog, since the OS won't show one anyway.
  ///
  /// Users who want to handle permissions individually (e.g. re-request a
  /// permanently denied one via Settings) can still use the permission
  /// cards below, which continue to open the dedicated screens.
  Future<void> _allowAndContinue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _requestIfNeeded(Permission.camera);
      await _requestIfNeeded(Permission.locationWhenInUse);
      await _requestIfNeeded(await _resolvePhotoPermission());
      await _requestIfNeeded(Permission.notification);
    } finally {
      if (!mounted) return;
      await _refreshStatuses();
    }

    if (!mounted) return;

    final allRequiredGranted =
        _cameraGranted && _locationGranted && _photosGranted;

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => allRequiredGranted
            ? const PermissionsEnabledScreen()
            : const PermissionRequiredScreen(),
      ),
      (route) => false,
    );
  }

  /// Resolves the correct "photos & media" permission for this exact
  /// device/OS combination. Must match PhotosMediaAccessScreen and
  /// PermissionFlowService's own resolution — Android 13+ uses
  /// Permission.photos, Android 12 and below uses Permission.storage,
  /// since permission_handler's internal auto-detection for
  /// Permission.photos is unreliable on some OEM builds (MIUI in
  /// particular).
  Future<Permission> _resolvePhotoPermission() async {
    if (!Platform.isAndroid) {
      return Permission.photos;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    return sdkInt >= 33 ? Permission.photos : Permission.storage;
  }

  /// Requests [permission] via the native dialog only if it isn't already
  /// resolved (granted or permanently denied). Permanently denied
  /// permissions won't show a dialog again -- those still need Settings,
  /// which is handled from the individual permission screens.
  Future<void> _requestIfNeeded(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted || status.isPermanentlyDenied) {
      return;
    }

    await permission.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Permissions',
        onBack: widget.onBack,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 600 ? 32.0 : AppSpacing.screenPadding;

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      20,
                    ),
                    children: [
                      Text(
                        _description,
                        style: AppTypography.body,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$_enabledCount of 4 enabled',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 18),


                      PermissionCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Camera',
                        subtitle: 'Capture geotagged photos',
                        accessLabel: 'Required',
                        accessLabelColor: AppColors.error,
                        showArrow: true,
                        onTap: () => _openPermission(
                          CameraAccessScreen(
                            onCameraGranted: () => Navigator.of(context).pop(),
                            onCameraSkipped: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      PermissionCard(
                        icon: Icons.location_on_outlined,
                        title: 'Precise Location',
                        subtitle: 'Add accurate GPS and address',
                        accessLabel: 'Required',
                        accessLabelColor: AppColors.error,
                        showArrow: true,
                        onTap: () => _openPermission(
                          LocationAccessScreen(
                            onLocationGranted: () =>
                                Navigator.of(context).pop(),
                            onLocationSkipped: () =>
                                Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      PermissionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Photos & Media',
                        subtitle: 'Save and import images',
                        accessLabel: 'Required',
                        accessLabelColor: AppColors.error,
                        showArrow: true,
                        onTap: () => _openPermission(
                          PhotosMediaAccessScreen(
                            onFinished: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      PermissionCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Capture and backup alerts',
                        accessLabel: 'Recommended',
                        accessLabelColor: AppColors.warning,
                        showArrow: true,
                        onTap: () => _openPermission(
                          NotificationAccessScreen(
                            onFinished: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    children: [
                      AppPrimaryButton(
                        label: 'Allow & Continue',
                        isLoading: _isLoading,
                        onPressed: _allowAndContinue,
                      ),
                      const SizedBox(height: 12),
                      const AppBanner(
                        message: _footnote,
                        tone: BannerTone.info,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}