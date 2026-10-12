import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'camera_access_screen.dart';
import 'location_access_screen.dart';
import 'notification_access_screen.dart';
import 'permission_page_route.dart';
import 'permission_recovery_dialog.dart';
import 'permissions_enabled_screen.dart';
import 'photos_media_access_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({
    super.key,
    this.showOnlyMissing = false,
  });

  final bool showOnlyMissing;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  static const String _description =
      '${AppBrand.name} needs the following permissions to work.';

  static const String _footnote = 'Location is added only when you capture.';

  bool _isLoading = true;

  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _photosGranted = false;
  bool _notificationGranted = false;
  bool _navigating = false;
  bool _isRequestingAll = false;
  bool _permissionRequestSequenceActive = false;
  late bool _showOnlyMissing;

  @override
  void initState() {
    super.initState();
    _showOnlyMissing = widget.showOnlyMissing;
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses(navigateWhenReady: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs also resume the app. Only the visible permission
    // center may react here; otherwise its hidden route could open the
    // Enabled screen while an information page is presenting the next OS
    // dialog (most visibly the Notifications dialog).
    if (state == AppLifecycleState.resumed &&
        !_permissionRequestSequenceActive &&
        ModalRoute.of(context)?.isCurrent == true) {
      _refreshStatuses(navigateWhenReady: true);
    }
  }

  Future<void> _refreshStatuses({bool navigateWhenReady = false}) async {
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

    if (navigateWhenReady &&
        !_permissionRequestSequenceActive &&
        ModalRoute.of(context)?.isCurrent == true &&
        camera &&
        location &&
        photos) {
      await _completeRequiredPermissions();
    }
  }

  int get _enabledCount => [
        _cameraGranted,
        _locationGranted,
        _photosGranted,
        _notificationGranted,
      ].where((granted) => granted).length;

  Future<void> _completeRequiredPermissions() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    await PermissionFlowService.completeRequiredPermissionFlow(context);
  }

  Future<void> _openPermission(Widget screen) async {
    await Navigator.of(context).push<void>(
      buildPermissionPageRoute<void>(screen),
    );
    await _refreshStatuses(navigateWhenReady: true);
  }

  bool _isGranted(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => _cameraGranted,
      ManagedAppPermission.location => _locationGranted,
      ManagedAppPermission.gallery => _photosGranted,
      ManagedAppPermission.notifications => _notificationGranted,
    };
  }

  /// Shows each matching information screen before requesting its missing
  /// OS permission. Required permissions control entry; Notifications stays
  /// recommended and never blocks the Enabled screen.
  Future<void> _allowAndContinue() async {
    if (_isLoading || _isRequestingAll) return;

    setState(() {
      _isRequestingAll = true;
      _permissionRequestSequenceActive = true;
    });

    try {
      final missingPermissions = PermissionFlowService.onboardingPermissions
          .where((permission) => !_isGranted(permission))
          .toList(growable: false);

      if (missingPermissions.isNotEmpty && mounted) {
        await Navigator.of(context).push<void>(
          buildPermissionPageRoute<void>(
            _PermissionRequestSequenceScreen(
              permissions: missingPermissions,
            ),
          ),
        );
      }

      if (!mounted || _navigating) return;

      final blocked =
          await PermissionFlowService.permanentlyDeniedPermissions(
        PermissionFlowService.onboardingPermissions,
      );
      if (blocked.isNotEmpty && mounted) {
        await PermissionRecoveryDialog.showBlockedPermissions(
          context,
          blocked,
        );
      }
    } catch (error) {
      debugPrint('Unable to request onboarding permissions: $error');
    } finally {
      if (!mounted) return;
      _permissionRequestSequenceActive = false;
      _isRequestingAll = false;
      await _refreshStatuses();
    }

    if (!mounted) return;

    final allRequiredGranted =
        _cameraGranted && _locationGranted && _photosGranted;

    if (allRequiredGranted) {
      await _completeRequiredPermissions();
      return;
    }

    setState(() {
      _showOnlyMissing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const AppTopBar(
          title: 'Permissions',
          showBack: false,
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

                      const AdBannerWidget(
                        format: AdDisplayFormat.mediumRectangle,
                        reserveSpaceWhileLoading: true,
                      ),

                      const SizedBox(height: 18),

                      if (!_showOnlyMissing || !_cameraGranted)
                        PermissionCard(
                          icon: Icons.camera_alt_outlined,
                          title: 'Camera',
                          subtitle: 'Capture geotagged photos',
                          accessLabel:
                              _cameraGranted ? 'Allowed' : 'Required',
                          accessLabelColor: _cameraGranted
                              ? AppColors.success
                              : AppColors.error,
                          trailingIcon: Icons.help_outline_rounded,
                          onTap: () => _openPermission(
                            const CameraAccessScreen(),
                          ),
                        ),

                      if (!_showOnlyMissing || !_cameraGranted)
                        const SizedBox(height: 10),

                      if (!_showOnlyMissing || !_locationGranted)
                        PermissionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Precise Location',
                          subtitle: 'Add accurate GPS and address',
                          accessLabel:
                              _locationGranted ? 'Allowed' : 'Required',
                          accessLabelColor: _locationGranted
                              ? AppColors.success
                              : AppColors.error,
                          trailingIcon: Icons.help_outline_rounded,
                          onTap: () => _openPermission(
                            const LocationAccessScreen(),
                          ),
                        ),

                      if (!_showOnlyMissing || !_locationGranted)
                        const SizedBox(height: 10),

                      if (!_showOnlyMissing || !_photosGranted)
                        PermissionCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Photos & Media',
                          subtitle: 'Save and import images',
                          accessLabel:
                              _photosGranted ? 'Allowed' : 'Required',
                          accessLabelColor: _photosGranted
                              ? AppColors.success
                              : AppColors.error,
                          trailingIcon: Icons.help_outline_rounded,
                          onTap: () => _openPermission(
                            const PhotosMediaAccessScreen(),
                          ),
                        ),

                      if (!_showOnlyMissing || !_photosGranted)
                        const SizedBox(height: 10),

                      if (!_showOnlyMissing || !_notificationGranted)
                        PermissionCard(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Capture and backup alerts',
                          accessLabel: _notificationGranted
                              ? 'Allowed'
                              : 'Recommended',
                          accessLabelColor: _notificationGranted
                              ? AppColors.success
                              : AppColors.warning,
                          trailingIcon: Icons.help_outline_rounded,
                          onTap: () => _openPermission(
                            const NotificationAccessScreen(),
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
                        isLoading: _isRequestingAll,
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
      ),
    );
  }
}

/// Keeps the automatic permission sequence inside one route. Each completed
/// permission step is replaced with a short fade/slide instead of popping to
/// the permission center and pushing a new page, which removes the visible
/// blink between operating-system permission dialogs.
class _PermissionRequestSequenceScreen extends StatefulWidget {
  const _PermissionRequestSequenceScreen({required this.permissions});

  final List<ManagedAppPermission> permissions;

  @override
  State<_PermissionRequestSequenceScreen> createState() =>
      _PermissionRequestSequenceScreenState();
}

class _PermissionRequestSequenceScreenState
    extends State<_PermissionRequestSequenceScreen> {
  int _currentIndex = 0;
  bool _advancing = false;
  bool _sequenceCompleted = false;

  void _advance() {
    if (_advancing || !mounted) return;
    _advancing = true;

    if (_currentIndex >= widget.permissions.length - 1) {
      setState(() => _sequenceCompleted = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    setState(() {
      _currentIndex += 1;
      _advancing = false;
    });
  }

  Widget _screenFor(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => CameraAccessScreen(
          key: const ValueKey('automatic-camera-permission'),
          requestOnOpen: true,
          onAutomaticFinished: _advance,
        ),
      ManagedAppPermission.location => LocationAccessScreen(
          key: const ValueKey('automatic-location-permission'),
          requestOnOpen: true,
          onAutomaticFinished: _advance,
        ),
      ManagedAppPermission.gallery => PhotosMediaAccessScreen(
          key: const ValueKey('automatic-gallery-permission'),
          requestOnOpen: true,
          onAutomaticFinished: _advance,
        ),
      ManagedAppPermission.notifications => NotificationAccessScreen(
          key: const ValueKey('automatic-notification-permission'),
          requestOnOpen: true,
          onAutomaticFinished: _advance,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final permission = widget.permissions[_currentIndex];

    return PopScope(
      canPop: _sequenceCompleted,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        reverseDuration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _screenFor(permission),
      ),
    );
  }
}
