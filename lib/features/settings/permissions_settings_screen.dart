import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../permission/permission_recovery_dialog.dart';
import '../permission/permissions_enabled_screen.dart';

/// Manages the app's operating-system permissions from one responsive screen.
/// Camera, location and gallery are required; notifications are recommended.
class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({
    super.key,
    this.requireForHome = false,
    this.onRequiredPermissionsGranted,
  });

  final bool requireForHome;
  final VoidCallback? onRequiredPermissionsGranted;

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _changing = false;
  bool _camera = false;
  bool _location = false;
  bool _gallery = false;
  bool _notifications = false;
  bool _completing = false;
  bool _recoveryLocked = false;
  bool _requiredDialogVisible = false;
  bool _requiredDialogShownForCurrentGap = false;

  bool get _requiredGranted => _camera && _location && _gallery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions(continueWhenReady: widget.requireForHome);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions(continueWhenReady: widget.requireForHome);
    }
  }

  Future<void> _refreshPermissions({bool continueWhenReady = false}) async {
    try {
      final camera = await PermissionFlowService.isCameraGranted();
      final location = await PermissionFlowService.isLocationGranted();
      final gallery = await PermissionFlowService.isPhotosGranted();
      final notifications =
          await PermissionFlowService.isNotificationGranted();

      if (!mounted) return;
      final requiredGranted = camera && location && gallery;
      setState(() {
        _camera = camera;
        _location = location;
        _gallery = gallery;
        _notifications = notifications;
        _recoveryLocked = !requiredGranted;
        _loading = false;
      });

      if (!requiredGranted && !_changing) {
        _showRequiredPermissionDialog();
      } else {
        _requiredDialogShownForCurrentGap = false;
      }

      if (continueWhenReady && requiredGranted) {
        await _completeRequiredPermissions();
      }
    } catch (error) {
      debugPrint('Unable to refresh permissions: $error');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeRequiredPermissions() async {
    if (_completing || !mounted) return;
    _completing = true;
    try {
      await PermissionFlowService.markOnboardingCompleted();
      unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());
      if (!mounted) return;

      final callback = widget.onRequiredPermissionsGranted;
      if (callback != null) {
        callback();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PermissionsEnabledScreen(),
          ),
          (route) => false,
        );
      }
    } catch (error) {
      debugPrint('Unable to complete permission setup: $error');
      _completing = false;
    }
  }

  Future<void> _showRequiredPermissionDialog() async {
    if (!mounted ||
        _requiredDialogVisible ||
        _requiredDialogShownForCurrentGap) {
      return;
    }

    _requiredDialogVisible = true;
    _requiredDialogShownForCurrentGap = true;

    final missing = <String>[
      if (!_camera) 'Camera',
      if (!_location) 'Location',
      if (!_gallery) 'Gallery',
    ];

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _requiredDialogVisible = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Required permission missing'),
        content: Text(
          '${missing.join(', ')} permission${missing.length == 1 ? '' : 's'} '
          '${missing.length == 1 ? 'is' : 'are'} required. Turn on the '
          'missing toggle${missing.length == 1 ? '' : 's'} to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );

    _requiredDialogVisible = false;
  }

  bool _isGranted(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => _camera,
      ManagedAppPermission.location => _location,
      ManagedAppPermission.gallery => _gallery,
      ManagedAppPermission.notifications => _notifications,
    };
  }

  String _permissionName(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => 'Camera',
      ManagedAppPermission.location => 'Location',
      ManagedAppPermission.gallery => 'Gallery',
      ManagedAppPermission.notifications => 'Notifications',
    };
  }

  Future<void> _changePermission(
    ManagedAppPermission permission,
    bool enable,
  ) async {
    if (_changing || _loading) return;

    if (enable) {
      setState(() => _changing = true);
      try {
        final needsWarning =
            await PermissionFlowService.shouldShowRequestWarning(permission);
        if (needsWarning && mounted) {
          await PermissionRecoveryDialog.showRepeatDenialToast(
            context,
            [permission],
          );
        }

        final granted =
            await PermissionFlowService.requestPermission(permission);
        await _refreshPermissions(
          continueWhenReady: widget.requireForHome,
        );

        if (!granted && mounted) {
          final blocked =
              await PermissionFlowService.isPermanentlyDenied(permission);
          if (blocked && mounted) {
            await PermissionRecoveryDialog.showBlockedPermissions(
              context,
              [permission],
            );
          }
        }
      } catch (error) {
        debugPrint('Unable to request permission: $error');
      } finally {
        if (mounted) setState(() => _changing = false);
      }
      return;
    }

    if (!enable && _isGranted(permission)) {
      await _showRevokeInSettingsDialog(permission);
      return;
    }

    await _refreshPermissions(
      continueWhenReady: widget.requireForHome,
    );
  }

  Future<void> _showRevokeInSettingsDialog(
    ManagedAppPermission permission,
  ) async {
    final name = _permissionName(permission);
    final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Turn off $name?'),
            content: Text(
              '$name permission must be turned off from the device app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;

    if (openSettings) {
      await PermissionFlowService.openSystemSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !widget.requireForHome && !_recoveryLocked && _requiredGranted,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppTopBar(
          title: 'Permissions',
          showBack: !widget.requireForHome && !_recoveryLocked,
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 48.0
                  : AppSpacing.screenPadding;

              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.md,
                        horizontalPadding,
                        24,
                      ),
                      children: [
                  Text(
                    _requiredGranted
                        ? 'Manage the access used by ${AppBrand.name}.'
                        : 'Enable Camera, Location and Gallery to continue to Home.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IgnorePointer(
                    ignoring: _changing,
                    child: Opacity(
                      opacity: _changing ? 0.65 : 1,
                      child: SettingsSectionCard(
                        children: [
                          ToggleSettingRow(
                            icon: Icons.camera_alt_outlined,
                            title: 'Camera',
                            subtitle: 'Required · Capture photos',
                            value: _camera,
                            onChanged: (value) => _changePermission(
                              ManagedAppPermission.camera,
                              value,
                            ),
                          ),
                          ToggleSettingRow(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            subtitle: 'Required · Add GPS stamp details',
                            value: _location,
                            onChanged: (value) => _changePermission(
                              ManagedAppPermission.location,
                              value,
                            ),
                          ),
                          ToggleSettingRow(
                            icon: Icons.photo_library_outlined,
                            title: 'Gallery',
                            subtitle: 'Required · Save and access photos',
                            value: _gallery,
                            onChanged: (value) => _changePermission(
                              ManagedAppPermission.gallery,
                              value,
                            ),
                          ),
                          Divider(height: 1, color: AppColors.border),
                          ToggleSettingRow(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Recommended · Receive app alerts',
                            value: _notifications,
                            onChanged: (value) => _changePermission(
                              ManagedAppPermission.notifications,
                              value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_requiredGranted) ...[
                    const SizedBox(height: AppSpacing.md),
                    const AppBanner(
                      message:
                          'Camera, Location and Gallery are required before the Home screen can open.',
                      tone: BannerTone.info,
                    ),
                  ],
                      ],
                    ),
                  ),
                  const AdBannerWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
