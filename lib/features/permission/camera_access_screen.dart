import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class CameraAccessScreen extends StatefulWidget {
  const CameraAccessScreen({
    super.key,
    this.onCameraGranted,
    this.onCameraSkipped,
  });

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

  // ---------------------------------------------------------------------------
  // CAMERA PERMISSION
  // ---------------------------------------------------------------------------

  Future<void> _allowCamera() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final currentStatus = await Permission.camera.status;

      // -----------------------------------------------------------------------
      // Already granted
      // -----------------------------------------------------------------------

      if (currentStatus.isGranted) {
        _cameraPermissionGranted();
        return;
      }

      // -----------------------------------------------------------------------
      // Request Android camera permission
      // -----------------------------------------------------------------------

      final result = await Permission.camera.request();

      if (!mounted) return;

      if (result.isGranted) {
        _cameraPermissionGranted();
        return;
      }

      // -----------------------------------------------------------------------
      // Permanently denied
      // -----------------------------------------------------------------------

      if (result.isPermanentlyDenied) {
        await _showPermissionSettingsDialog();
        return;
      }

      // -----------------------------------------------------------------------
      // Denied / restricted
      // -----------------------------------------------------------------------

      setState(() {
        _isRequesting = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isRequesting = false;
      });
    }
  }

  // void _cameraPermissionGranted() {
  //   if (!mounted) return;

  //   setState(() {
  //     _isRequesting = false;
  //   });

  //   if (widget.onCameraGranted != null) {
  //     widget.onCameraGranted!();
  //     return;
  //   }

  //   // The next permission screen will be connected here.
  //   //
  //   // Example:
  //   //
  //   // Navigator.of(context).push(
  //   //   MaterialPageRoute(
  //   //     builder: (_) => const LocationAccessScreen(),
  //   //   ),
  //   // );
  // }

  Future<void> _cameraPermissionGranted() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    if (widget.onCameraGranted != null) {
      widget.onCameraGranted!();
      return;
    }

    await PermissionFlowService.advance(context, from: PermissionStep.camera);
  }






  // ---------------------------------------------------------------------------
  // PERMISSION SETTINGS
  // ---------------------------------------------------------------------------

  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Camera permission required'),
          content: const Text(
            'Camera permission has been disabled for GeoStamp Camera. '
            'In Settings, select Permissions and allow camera access.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Manage App Permissions'),
            ),
          ],
        );
      },
    );
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
      backgroundColor: AppColors.background,

      appBar: AppTopBar(
        title: '',
        onBack: _notNow,
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
                        // -----------------------------------------------------
                        // CAMERA ICON
                        // -----------------------------------------------------

                        Container(
                          width: width >= 600 ? 92 : 78,
                          height: width >= 600 ? 92 : 78,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E7FF),
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
                            'GeoStamp Camera needs camera access '
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
                              // Background scene approximation using
                              // existing Flutter primitives.
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF9CB5C8),
                                      Color(0xFF6F8590),
                                      Color(0xFF70513B),
                                    ],
                                    stops: [
                                      0.0,
                                      0.48,
                                      1.0,
                                    ],
                                  ),
                                ),
                              ),

                              // Building / camera preview composition.
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 20,
                                child: Container(
                                  height: previewHeight * 0.40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF745B49),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomPaint(
                                    painter: _BuildingPreviewPainter(),
                                  ),
                                ),
                              ),

                              // GPS stamp overlay.
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(
                                      alpha: 0.65,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Tirunelveli, Tamil Nadu, India\n'
                                    '8.7278° N, 77.7017° E\n'
                                    '±16 m  ·  28°C  ·  1021 hPa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // Location marker.
                              Positioned(
                                left: 14,
                                bottom: 34,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.location_on,
                                    size: 22,
                                    color: AppColors.primary,
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
                          text: 'Scan QR codes',
                        ),
                      ],
                    ),
                  ),
                ),

                // -------------------------------------------------------------
                // BOTTOM ACTIONS
                // -------------------------------------------------------------

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
                        label: 'Allow Camera',
                        isLoading: _isRequesting,
                        onPressed: _allowCamera,
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _isRequesting ? null : _notNow,
                        child: Text(
                          'Not Now',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}

// =============================================================================
// PREVIEW PAINTER
// =============================================================================
//
// This is not a reusable widget. It is only the visual painting implementation
// used inside this screen so we don't introduce another common widget.
// =============================================================================

class _BuildingPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final buildingPaint = Paint()
      ..color = const Color(0xFF8E806E)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFF4F453D)
      ..style = PaintingStyle.fill;

    final cranePaint = Paint()
      ..color = const Color(0xFF343434)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final building = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.10,
      size.width * 0.40,
      size.height * 0.90,
    );

    canvas.drawRect(building, buildingPaint);

    // Building floors.
    for (var i = 1; i < 6; i++) {
      final y = size.height * (i / 6);

      canvas.drawLine(
        Offset(
          size.width * 0.12,
          y,
        ),
        Offset(
          size.width * 0.52,
          y,
        ),
        darkPaint,
      );
    }

    // Vertical construction lines.
    for (var i = 1; i < 5; i++) {
      final x = size.width * (0.12 + (0.40 * i / 5));

      canvas.drawLine(
        Offset(
          x,
          size.height * 0.10,
        ),
        Offset(
          x,
          size.height,
        ),
        darkPaint,
      );
    }

    // Crane.
    canvas.drawLine(
      Offset(
        size.width * 0.47,
        size.height * 0.08,
      ),
      Offset(
        size.width * 0.80,
        size.height * 0.08,
      ),
      cranePaint,
    );

    canvas.drawLine(
      Offset(
        size.width * 0.52,
        size.height * 0.08,
      ),
      Offset(
        size.width * 0.52,
        size.height * 0.85,
      ),
      cranePaint,
    );

    canvas.drawLine(
      Offset(
        size.width * 0.68,
        size.height * 0.08,
      ),
      Offset(
        size.width * 0.62,
        size.height * 0.50,
      ),
      cranePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
