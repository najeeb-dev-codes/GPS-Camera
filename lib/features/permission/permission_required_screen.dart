



import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../home/home_screen.dart';
import 'permission_screen.dart';

class PermissionRequiredScreen extends StatefulWidget {
  const PermissionRequiredScreen({super.key});

  @override
  State<PermissionRequiredScreen> createState() =>
      _PermissionRequiredScreenState();
}

class _PermissionRequiredScreenState extends State<PermissionRequiredScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _camera = false;
  bool _location = false;
  bool _photos = false;
  bool _navigatingHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh(navigateToHome: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh(navigateToHome: true);
    }
  }

  Future<void> _refresh({bool navigateToHome = false}) async {
    final camera = await PermissionFlowService.isCameraGranted();
    final location = await PermissionFlowService.isLocationGranted();
    final photos = await PermissionFlowService.isPhotosGranted();
    if (!mounted) return;

    if (navigateToHome && camera && location && photos) {
      await _continueToHome();
      return;
    }

    setState(() {
      _camera = camera;
      _location = location;
      _photos = photos;
      _loading = false;
    });
  }

  int get _missingCount =>
      [_camera, _location, _photos].where((e) => !e).length;

  String get _title {
    if (_missingCount > 1) return 'Permissions are required';
    if (!_camera) return 'Camera permission is required';
    if (!_location) return 'Location permission is required';
    if (!_photos) return 'Photo permission is required';
    return 'All permissions are enabled';
  }

  Future<void> _tryAgain() async {
    if (_loading || _navigatingHome) return;
    setState(() => _loading = true);
    await _refresh(navigateToHome: true);
  }

  Future<void> _continueToHome() async {
    if (_navigatingHome || !mounted) return;
    _navigatingHome = true;

    await PermissionFlowService.markOnboardingCompleted();
    unawaited(DeviceRegistrationService.registerAfterPermissionsChanged());

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  

  void _backToPermissions() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PermissionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: '', onBack: _backToPermissions),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding =
                constraints.maxWidth >= 600 ? 48.0 : AppSpacing.screenPadding;
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEC),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: AppColors.error,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: AppTypography.h2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enable the missing permission${_missingCount == 1 ? '' : 's'} '
                        'to capture verified geotagged photos.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_camera) ...[
                        const PermissionCard(
                          icon: Icons.camera_alt_outlined,
                          title: 'Camera',
                          subtitle: 'Capture geotagged photos',
                          status: 'Denied',
                          statusColor: AppColors.error,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!_location) ...[
                        const PermissionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Precise Location',
                          subtitle: 'Add accurate GPS and address',
                          status: 'Denied',
                          statusColor: AppColors.error,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!_photos)
                        const PermissionCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Photos & Media',
                          subtitle: 'Save and import images',
                          status: 'Denied',
                          statusColor: AppColors.error,
                        ),
                      const SizedBox(height: 20),
                      const AppBanner(
                        message:
                            'In Settings, select Permissions and allow the missing access.',
                        tone: BannerTone.info,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                  child: Column(
                    children: [
                   AppPrimaryButton(
  label: 'Manage Permissions',
  onPressed: _backToPermissions,
),
                      const SizedBox(height: 8),
                      AppSecondaryButton(
                          label: 'Try Again', onPressed: _tryAgain),
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
