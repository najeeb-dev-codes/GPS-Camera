import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/device_registration_service.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({
    super.key,
    this.onLocationGranted,
    this.onLocationSkipped,
  });

  /// Called when precise location permission has been granted.
  ///
  /// The permission flow can connect this to
  /// PhotosMediaAccessScreen later.
  final VoidCallback? onLocationGranted;
  final VoidCallback? onLocationSkipped;

  @override
  State<LocationAccessScreen> createState() =>
      _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  bool _isRequesting = false;

  // ---------------------------------------------------------------------------
  // LOCATION PERMISSION
  // ---------------------------------------------------------------------------

  Future<void> _allowLocation() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final currentStatus = await Permission.locationWhenInUse.status;

      // -----------------------------------------------------------------------
      // Already granted
      // -----------------------------------------------------------------------

      if (currentStatus.isGranted) {
        _locationPermissionGranted();
        return;
      }

      // -----------------------------------------------------------------------
      // Request location while app is being used.
      //
      // Android will show its own location permission dialog.
      // -----------------------------------------------------------------------

      final result =
          await Permission.locationWhenInUse.request();

      if (!mounted) return;

      // -----------------------------------------------------------------------
      // Granted
      // -----------------------------------------------------------------------

      if (result.isGranted) {
        // Check whether Android granted precise or approximate location.
        final locationServiceStatus =
            await Permission.locationWhenInUse.status;

        if (locationServiceStatus.isGranted) {
          _locationPermissionGranted();
        } else {
          setState(() {
            _isRequesting = false;
          });
        }

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
      // Denied
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

  // ---------------------------------------------------------------------------
  // LOCATION GRANTED
  // ---------------------------------------------------------------------------

  Future<void> _locationPermissionGranted() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    // Location is now granted. Immediately request a fresh backend
    // registration so the payload can include the location fields the
    // backend expects: latitude, longitude, city, state, country and
    // country_code. This is intentionally fire-and-forget so GPS/network
    // work never blocks the permission-screen navigation.
    unawaited(
      DeviceRegistrationService.registerAfterPermissionsChanged(),
    );

    if (widget.onLocationGranted != null) {
      widget.onLocationGranted!();
      return;
    }

    await PermissionFlowService.advance(
      context,
      from: PermissionStep.location,
    );
  }

  // ---------------------------------------------------------------------------
  // SETTINGS DIALOG
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
          title: const Text(
            'Location permission required',
          ),
          content: const Text(
            'Location permission has been disabled for '
            'GeoStamp Camera. In Settings, select Permissions '
            'and allow location access.',
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
  // SKIP
  // ---------------------------------------------------------------------------

  Future<void> _skipForNow() async {
    if (widget.onLocationSkipped != null) {
      widget.onLocationSkipped!();
      return;
    }

    await PermissionFlowService.advance(
      context,
      from: PermissionStep.location,
    );
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
        onBack: _skipForNow,
      ),

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            final mapHeight = width >= 600
                ? 270.0
                : width < 360
                    ? 190.0
                    : 220.0;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      children: [
                        // -----------------------------------------------------
                        // LOCATION ICON
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
                            Icons.location_on_rounded,
                            size: width >= 600 ? 56 : 46,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // HEADING
                        // -----------------------------------------------------

                        Text(
                          'Add accurate location',
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
                            'Use GPS to add address, coordinates, '
                            'date, and weather to your photo.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // -----------------------------------------------------
                        // MAP PREVIEW
                        // -----------------------------------------------------

                        Container(
                          width: double.infinity,
                          height: mapHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4EBDD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // -------------------------------------------------
                              // MAP BACKGROUND
                              // -------------------------------------------------

                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _MapPreviewPainter(),
                                ),
                              ),

                              // -------------------------------------------------
                              // CENTER LOCATION PIN
                              // -------------------------------------------------

                              Align(
                                alignment: const Alignment(
                                  0.0,
                                  -0.05,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  size: 52,
                                  color: AppColors.primary,
                                ),
                              ),

                              // -------------------------------------------------
                              // LOCATION INFORMATION
                              // -------------------------------------------------

                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tirunelveli, Tamil Nadu, India',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: AppTypography.caption
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '8.7278° N, 77.7017° E',
                                        style:
                                            AppTypography.caption
                                                .copyWith(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '± 16 m  •  18 Aug 2025  •  09:25 AM',
                                        style:
                                            AppTypography.caption
                                                .copyWith(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondary,
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
                        // PRIVACY / LOCATION INFORMATION
                        // -----------------------------------------------------

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Location is requested only while '
                                  'you use the camera.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        label: 'Allow Location',
                        isLoading: _isRequesting,
                        onPressed: _allowLocation,
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed:
                            _isRequesting ? null : _skipForNow,
                        child: Text(
                          'Skip for Now',
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
}

// =============================================================================
// MAP PREVIEW
// =============================================================================
//
// Screen-local painter only.
// No new reusable/common widget is introduced.
// =============================================================================

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE7EEDC)
      ..style = PaintingStyle.fill;

    final landPaint = Paint()
      ..color = const Color(0xFFD9E4D0)
      ..style = PaintingStyle.fill;

    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final smallRoadPaint = Paint()
      ..color = const Color(0xFFF4F4F0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFFD2E3EF)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    // -------------------------------------------------------------------------
    // LAND BLOCKS
    // -------------------------------------------------------------------------

    final land1 = Path()
      ..moveTo(0, size.height * .10)
      ..lineTo(size.width * .35, 0)
      ..lineTo(size.width * .48, size.height * .30)
      ..lineTo(size.width * .22, size.height * .46)
      ..lineTo(0, size.height * .40)
      ..close();

    canvas.drawPath(
      land1,
      landPaint,
    );

    final land2 = Path()
      ..moveTo(size.width * .65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .35)
      ..lineTo(size.width * .74, size.height * .44)
      ..lineTo(size.width * .56, size.height * .23)
      ..close();

    canvas.drawPath(
      land2,
      landPaint,
    );

    final land3 = Path()
      ..moveTo(0, size.height * .58)
      ..lineTo(size.width * .26, size.height * .43)
      ..lineTo(size.width * .50, size.height * .65)
      ..lineTo(size.width * .34, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      land3,
      landPaint,
    );

    // -------------------------------------------------------------------------
    // WATER
    // -------------------------------------------------------------------------

    final water = Path()
      ..moveTo(size.width * .78, size.height * .48)
      ..quadraticBezierTo(
        size.width * .62,
        size.height * .60,
        size.width * .75,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * .42)
      ..close();

    canvas.drawPath(
      water,
      waterPaint,
    );

    // -------------------------------------------------------------------------
    // MAIN ROADS
    // -------------------------------------------------------------------------

    final mainRoad = Path()
      ..moveTo(
        size.width * .05,
        size.height * .85,
      )
      ..quadraticBezierTo(
        size.width * .30,
        size.height * .58,
        size.width * .55,
        size.height * .46,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .35,
        size.width * .96,
        size.height * .08,
      );

    canvas.drawPath(
      mainRoad,
      roadPaint,
    );

    final secondRoad = Path()
      ..moveTo(
        size.width * .08,
        size.height * .05,
      )
      ..quadraticBezierTo(
        size.width * .32,
        size.height * .35,
        size.width * .58,
        size.height * .55,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .70,
        size.width * .94,
        size.height * .88,
      );

    canvas.drawPath(
      secondRoad,
      roadPaint,
    );

    // -------------------------------------------------------------------------
    // SMALL ROADS
    // -------------------------------------------------------------------------

    final smallRoad1 = Path()
      ..moveTo(
        size.width * .12,
        size.height * .62,
      )
      ..lineTo(
        size.width * .72,
        size.height * .20,
      );

    canvas.drawPath(
      smallRoad1,
      smallRoadPaint,
    );

    final smallRoad2 = Path()
      ..moveTo(
        size.width * .38,
        0,
      )
      ..lineTo(
        size.width * .45,
        size.height,
      );

    canvas.drawPath(
      smallRoad2,
      smallRoadPaint,
    );

    final smallRoad3 = Path()
      ..moveTo(
        size.width * .12,
        size.height * .20,
      )
      ..lineTo(
        size.width * .85,
        size.height * .72,
      );

    canvas.drawPath(
      smallRoad3,
      smallRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
