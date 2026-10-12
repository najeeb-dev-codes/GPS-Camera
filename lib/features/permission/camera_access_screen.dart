import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'permission_ad_gate.dart';
import 'permission_recovery_dialog.dart';

class CameraAccessScreen extends StatefulWidget {
  const CameraAccessScreen({
    super.key,
    this.requestOnOpen = false,
    this.onAutomaticFinished,
    this.onCameraGranted,
    this.onCameraSkipped,
  });

  final bool requestOnOpen;
  final VoidCallback? onAutomaticFinished;
  /// Called after the camera permission has been successfully granted.
  ///
  /// The permission flow can connect this to LocationAccessScreen later.
  final VoidCallback? onCameraGranted;
  final VoidCallback? onCameraSkipped;

  @override
  State<CameraAccessScreen> createState() => _CameraAccessScreenState();
}

class _CameraAccessScreenState extends State<CameraAccessScreen> {
  bool _isRequesting = false;
  bool _automaticRequestFinished = false;

  void _finishAutomaticRequest() {
    if (!widget.requestOnOpen ||
        !mounted ||
        _automaticRequestFinished) {
      return;
    }

    _automaticRequestFinished = true;
    final onFinished = widget.onAutomaticFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // CAMERA PERMISSION
  // ---------------------------------------------------------------------------

  Future<void> _allowCamera() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      if (await PermissionFlowService.isCameraGranted()) {
        _cameraPermissionGranted();
        return;
      }

      final needsWarning =
          await PermissionFlowService.shouldShowRequestWarning(
        ManagedAppPermission.camera,
      );
      if (needsWarning && mounted) {
        await PermissionRecoveryDialog.showRepeatDenialToast(
          context,
          const [ManagedAppPermission.camera],
        );
      }

      final granted = await PermissionFlowService.requestPermission(
        ManagedAppPermission.camera,
      );

      if (!mounted) return;

      if (granted) {
        _cameraPermissionGranted();
        return;
      }

      if (mounted) setState(() => _isRequesting = false);
      _finishAutomaticRequest();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isRequesting = false;
      });
      _finishAutomaticRequest();
    }
  }

  Future<void> _cameraPermissionGranted() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    if (widget.requestOnOpen) {
      _finishAutomaticRequest();
      return;
    }

    if (widget.onCameraGranted != null) {
      widget.onCameraGranted!();
      return;
    }

    await PermissionFlowService.advance(context, from: PermissionStep.camera);
  }

  // ---------------------------------------------------------------------------
  // NOT NOW
  // ---------------------------------------------------------------------------

  Future<void> _notNow() async {
    // Camera is required, but we still let the user defer it and continue
    // through the rest of the flow — the gap gets caught by the final
    // Permission Required screen.
    if (widget.onCameraSkipped != null) {
      widget.onCameraSkipped!();
      return;
    }

    await PermissionFlowService.advance(context, from: PermissionStep.camera);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppTopBar(
        title: '',
        showBack: !widget.requestOnOpen,
        onBack: () => Navigator.of(context).pop(),
      ),

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            final previewHeight = width >= 600
                ? 230.0
                : width < 360
                    ? 170.0
                    : 200.0;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      children: [
                        if (widget.requestOnOpen) ...[
                          PermissionAdGate(
                            onReady: () {
                              _allowCamera();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        // -----------------------------------------------------
                        // CAMERA ICON
                        // -----------------------------------------------------

                        Container(
                          width: width >= 600 ? 92 : 78,
                          height: width >= 600 ? 92 : 78,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: width >= 600 ? 54 : 46,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // HEADING
                        // -----------------------------------------------------

                        Text(
                          'Allow camera access',
                          textAlign: TextAlign.center,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // -----------------------------------------------------
                        // DESCRIPTION
                        // -----------------------------------------------------

                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 340,
                          ),
                          child: Text(
                            '${AppBrand.name} needs camera access '
                            'to capture photos with GPS stamps.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // -----------------------------------------------------
                        // PREVIEW IMAGE AREA
                        // -----------------------------------------------------

                        Container(
                          width: double.infinity,
                          height: previewHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE5EE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/stampbg.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.mutedSurface,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),

                              // GPS stamp overlay.
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(
                                      alpha: 0.78,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          size: 25,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Tirunelveli, Tamil Nadu, India\n'
                                          '8.7278° N, 77.7017° E\n'
                                          '18 Aug 2025  ·  09:25 AM',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            height: 1.25,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // FEATURE POINTS
                        // -----------------------------------------------------

                        _buildFeaturePoint(
                          icon: Icons.check_circle,
                          text: 'Capture photos',
                        ),

                        const SizedBox(height: 8),

                        _buildFeaturePoint(
                          icon: Icons.check_circle,
                          text: 'Preview stamps',
                        ),

                        const SizedBox(height: 8),

                        _buildFeaturePoint(
                          icon: Icons.check_circle,
                          text: 'Add GPS stamps',
                        ),

                        const SizedBox(height: 20),

                        // -----------------------------------------------------
                        // CAMERA ACCESS USAGE
                        // -----------------------------------------------------

                        _buildCameraUsageSection(),
                        if (!widget.requestOnOpen) ...[
                          const SizedBox(height: 20),
                          const AdBannerWidget(
                            format: AdDisplayFormat.mediumRectangle,
                            reserveSpaceWhileLoading: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURE POINT
  // ---------------------------------------------------------------------------

  Widget _buildFeaturePoint({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraUsageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How camera access is used',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildUsagePoint(
            'The camera opens only from the capture screen.',
          ),
          const SizedBox(height: 7),
          _buildUsagePoint(
            'You can preview and retake before saving.',
          ),
          const SizedBox(height: 7),
          _buildUsagePoint(
            'Photos stay on your device until you choose to save them.',
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
