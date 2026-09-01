import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

class PhotosMediaAccessScreen extends StatefulWidget {
  const PhotosMediaAccessScreen({
    super.key,
    this.onFinished,
  });

  final VoidCallback? onFinished;

  @override
  State<PhotosMediaAccessScreen> createState() =>
      _PhotosMediaAccessScreenState();
}

class _PhotosMediaAccessScreenState
    extends State<PhotosMediaAccessScreen> {
  bool _isRequesting = false;

  // ---------------------------------------------------------------------------
  // PLATFORM-AWARE PERMISSION RESOLUTION
  // ---------------------------------------------------------------------------
  //
  // permission_handler's `Permission.photos` is *supposed* to map itself to
  // the right underlying Android permission (READ_MEDIA_IMAGES on 13+,
  // READ_EXTERNAL_STORAGE on 12 and below), but on some OEM builds (MIUI in
  // particular) that internal SDK-version detection is unreliable and
  // `.request()` can return `denied`/`restricted` instantly, with no dialog
  // ever shown, on Android 12 and below.
  //
  // To make this work consistently across every Android version (and iOS),
  // we resolve the SDK level ourselves via device_info_plus and pick the
  // permission explicitly instead of trusting the plugin's internal guess.

  /// Returns the single [Permission] to request for "photos & media" access
  /// on this exact device/OS combination.
  Future<Permission> _resolvePhotoPermission() async {
    if (!Platform.isAndroid) {
      // iOS (and any other platform permission_handler supports) — Photos
      // is the correct, single permission everywhere.
      return Permission.photos;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ (API 33+): granular media permission.
      return Permission.photos;
    }

    // Android 12 (API 32) and below: legacy storage permission.
    return Permission.storage;
  }

  Future<void> _allowPhotoAccess() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final permission = await _resolvePhotoPermission();

      if (!mounted) return;

      final currentStatus = await permission.status;

      // -----------------------------------------------------------------------
      // Already granted
      // -----------------------------------------------------------------------

      if (currentStatus.isGranted || currentStatus.isLimited) {
        await _photoPermissionGranted();
        return;
      }

      // -----------------------------------------------------------------------
      // Request the resolved permission
      // -----------------------------------------------------------------------

      final result = await permission.request();

      if (!mounted) return;

      if (result.isGranted || result.isLimited) {
        await _photoPermissionGranted();
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

  // ---------------------------------------------------------------------------
  // PHOTO PERMISSION GRANTED
  // ---------------------------------------------------------------------------

  Future<void> _photoPermissionGranted() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    await PermissionFlowService.advance(context, from: PermissionStep.photos);
  }

  // ---------------------------------------------------------------------------
  // NOT NOW
  // ---------------------------------------------------------------------------

  Future<void> _notNow() async {
    await PermissionFlowService.advance(context, from: PermissionStep.photos);
  }

  // ---------------------------------------------------------------------------
  // SETTINGS
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
            'Photo access required',
          ),
          content: const Text(
            'Photo access has been disabled for GeoStamp Camera. '
            'In Settings, select Permissions and allow photo access.',
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
                        // PHOTO ICON
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
                            Icons.photo_library_outlined,
                            size: width >= 600 ? 56 : 46,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // HEADING
                        // -----------------------------------------------------

                        Text(
                          'Save your photos',
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
                            maxWidth: 350,
                          ),
                          child: Text(
                            'Allow access to save your captured '
                            'photos with GPS stamps to your gallery.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // -----------------------------------------------------
                        // SAVE CAPTURES
                        // -----------------------------------------------------

                        _buildInfoCard(
                          icon: Icons.save_alt_rounded,
                          title: 'Save Captures',
                          description:
                              'Save geotagged photos to your gallery.',
                        ),

                        const SizedBox(height: 10),

                        // -----------------------------------------------------
                        // ORGANIZE GALLERY
                        // -----------------------------------------------------

                        _buildInfoCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Organize Gallery',
                          description:
                              'Keep your captured photos organized.',
                        ),

                        const SizedBox(height: 10),

                        // -----------------------------------------------------
                        // PRIVACY INFORMATION
                        // -----------------------------------------------------

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD8C1FF),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Photo access is used only to save '
                                  'your captured photos to your device.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textPrimary,
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
                        label: 'Allow Photo Access',
                        isLoading: _isRequesting,
                        onPressed: _allowPhotoAccess,
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed:
                            _isRequesting ? null : _notNow,
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
  // INFO CARD
  // ---------------------------------------------------------------------------

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
