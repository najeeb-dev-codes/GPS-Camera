import 'package:flutter/material.dart';

import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_screen.dart';
import 'permission_screen.dart';

class PermissionsEnabledScreen extends StatefulWidget {
  const PermissionsEnabledScreen({super.key});

  @override
  State<PermissionsEnabledScreen> createState() =>
      _PermissionsEnabledScreenState();
}

class _PermissionsEnabledScreenState
    extends State<PermissionsEnabledScreen>
    with WidgetsBindingObserver {
  bool _loading = true;

  bool _camera = false;
  bool _location = false;
  bool _photos = false;
  bool _notifications = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  Future<void> _initialize() async {
    await PermissionFlowService.markOnboardingCompleted();

    await _refresh();

    // Important:
    // Permissions have now finished being granted/denied.
    // Send a fresh device payload to backend.
    await DeviceRegistrationService.registerAfterPermissionsChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _refreshAndSync();
    }
  }

  Future<void> _refreshAndSync() async {
    await _refresh();

    await DeviceRegistrationService.registerAfterPermissionsChanged();
  }

  Future<void> _refresh() async {
    final camera =
        await PermissionFlowService.isCameraGranted();

    final location =
        await PermissionFlowService.isLocationGranted();

    final photos =
        await PermissionFlowService.isPhotosGranted();

    final notifications =
        await PermissionFlowService.isNotificationGranted();

    if (!mounted) return;

    setState(() {
      _camera = camera;
      _location = location;
      _photos = photos;
      _notifications = notifications;
      _loading = false;
    });
  }

  void _continueToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _managePermissions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PermissionScreen(),
      ),
    );

    if (!mounted) return;

    await _refreshAndSync();
  }

  Widget _permissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
  }) {
    return PermissionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      status: granted ? 'Allowed' : 'Denied',
      statusColor:
          granted ? AppColors.success : AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 600
                    ? 48.0
                    : AppSpacing.screenPadding;

            if (_loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(
                        top: 24,
                        bottom: 20,
                      ),
                      children: [
                        const SuccessStateView(
                          title: "You're ready to capture",
                          subtitle:
                              'All required permissions are enabled.',
                        ),

                        const SizedBox(height: 24),

                        _permissionCard(
                          icon: Icons.camera_alt_outlined,
                          title: 'Camera',
                          subtitle:
                              'Capture geotagged photos',
                          granted: _camera,
                        ),

                        const SizedBox(height: 8),

                        _permissionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Precise Location',
                          subtitle:
                              'Add accurate GPS and address',
                          granted: _location,
                        ),

                        const SizedBox(height: 8),

                        _permissionCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Photos & Media',
                          subtitle:
                              'Save and import images',
                          granted: _photos,
                        ),

                        const SizedBox(height: 8),

                        _permissionCard(
                          icon:
                              Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle:
                              'Capture and backup alerts',
                          granted: _notifications,
                        ),

                        const SizedBox(height: 20),

                        const AppBanner(
                          message:
                              'Your data stays on your device',
                          tone: BannerTone.success,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        AppPrimaryButton(
                          label: 'Continue to Home',
                          onPressed: _continueToHome,
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: _managePermissions,
                          child: Text(
                            'Manage Permissions',
                            style:
                                AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
