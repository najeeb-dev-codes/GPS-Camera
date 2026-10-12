import 'package:flutter/material.dart';
import 'package:gps_mark/features/permission/permission_screen.dart';

import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_screen.dart';
import 'permission_page_route.dart';

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
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  Future<void> _initialize() async {
    await PermissionFlowService.markOnboardingCompleted();

    final requiredGranted = await _refresh();

    if (!requiredGranted) {
      _showRequiredScreen();
      return;
    }

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
    final requiredGranted = await _refresh();

    if (!requiredGranted) {
      _showRequiredScreen();
      return;
    }

    await DeviceRegistrationService.registerAfterPermissionsChanged();
  }

  Future<bool> _refresh() async {
    final camera =
        await PermissionFlowService.isCameraGranted();

    final location =
        await PermissionFlowService.isLocationGranted();

    final photos =
        await PermissionFlowService.isPhotosGranted();

    final notifications =
        await PermissionFlowService.isNotificationGranted();

    if (!mounted) return false;

    setState(() {
      _camera = camera;
      _location = location;
      _photos = photos;
      _notifications = notifications;
      _loading = false;
    });

    return camera && location && photos;
  }

  void _continueToHome() {
    if (_navigating || !_camera || !_location || !_photos) return;
    _navigating = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  void _showRequiredScreen() {
    if (_navigating || !mounted) return;
    _navigating = true;
    Navigator.of(context).pushAndRemoveUntil(
      buildPermissionPageRoute<void>(
        const PermissionScreen(showOnlyMissing: true),
      ),
      (route) => false,
    );
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        top: 16,
                        bottom: 20,
                      ),
                      children: [
                        // Same full-width banner used on the Home screen,
                        // shown at the top of this screen.
                        const SizedBox(
                          width: double.infinity,
                          child: AdBannerWidget(
                            format: AdDisplayFormat.adaptiveBanner,
                            reserveSpaceWhileLoading: true,
                            slotHeight: 80,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const SuccessStateView(
                          title: "Permissions restored",
                          subtitle:
                              'All required permissions are enabled.',
                        ),

                        const SizedBox(height: 24),

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
                      ],
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }
}