import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'permission_ad_gate.dart';
import 'permission_recovery_dialog.dart';

class PhotosMediaAccessScreen extends StatefulWidget {
  const PhotosMediaAccessScreen({
    super.key,
    this.requestOnOpen = false,
    this.onAutomaticFinished,
    this.onFinished,
  });

  final bool requestOnOpen;
  final VoidCallback? onAutomaticFinished;
  final VoidCallback? onFinished;

  @override
  State<PhotosMediaAccessScreen> createState() =>
      _PhotosMediaAccessScreenState();
}

class _PhotosMediaAccessScreenState
    extends State<PhotosMediaAccessScreen> {
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

  Future<void> _allowPhotoAccess() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      if (await PermissionFlowService.isPhotosGranted()) {
        await _photoPermissionGranted();
        return;
      }

      final needsWarning =
          await PermissionFlowService.shouldShowRequestWarning(
        ManagedAppPermission.gallery,
      );
      if (needsWarning && mounted) {
        await PermissionRecoveryDialog.showRepeatDenialToast(
          context,
          const [ManagedAppPermission.gallery],
        );
      }

      final granted = await PermissionFlowService.requestPermission(
        ManagedAppPermission.gallery,
      );

      if (!mounted) return;

      if (granted) {
        await _photoPermissionGranted();
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

  // ---------------------------------------------------------------------------
  // PHOTO PERMISSION GRANTED
  // ---------------------------------------------------------------------------

  Future<void> _photoPermissionGranted() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    if (widget.requestOnOpen) {
      _finishAutomaticRequest();
      return;
    }

    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    await PermissionFlowService.advance(context, from: PermissionStep.photos);
  }

  // ---------------------------------------------------------------------------
  // NOT NOW
  // ---------------------------------------------------------------------------

  Future<void> _notNow() async {
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    await PermissionFlowService.advance(context, from: PermissionStep.photos);
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
                        if (widget.requestOnOpen) ...[
                          PermissionAdGate(
                            onReady: () {
                              _allowPhotoAccess();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        // -----------------------------------------------------
                        // PHOTO ICON
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
                          'Photos & media',
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
                            'Photo access lets ${AppBrand.name} save your captures '
                            'and show them in the in-app gallery.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // -----------------------------------------------------
                        // SITE VISIT GALLERY PREVIEW
                        // -----------------------------------------------------

                        _buildSiteVisitPreview(),

                        const SizedBox(height: 12),

                        // -----------------------------------------------------
                        // SAVE CAPTURES
                        // -----------------------------------------------------

                        _buildInfoCard(
                          icon: Icons.download_rounded,
                          title: 'Save captured photos',
                          description:
                              'Keep stamped photos safely on your device.',
                        ),

                        const SizedBox(height: 10),

                        // -----------------------------------------------------
                        // ORGANIZE GALLERY
                        // -----------------------------------------------------

                        _buildInfoCard(
                          icon: Icons.photo_library_outlined,
                          title: 'View your gallery',
                          description:
                              'Open and review your saved captures.',
                        ),

                        const SizedBox(height: 10),

                        _buildInfoCard(
                          icon: Icons.folder_outlined,
                          title: 'Organize by project',
                          description:
                              'Group related site photos into projects.',
                        ),

                        const SizedBox(height: 10),

                        _buildInfoCard(
                          icon: Icons.share_outlined,
                          title: 'Share & export photos',
                          description:
                              'Share captures or export a project as PDF.',
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
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.55,
                              ),
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
  // SITE VISIT PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildSiteVisitPreview() {
    const photos = <_SiteVisitPhoto>[
      _SiteVisitPhoto(
        assetPath: 'assets/images/construction1.png',
        location: 'Avadi, Chennai, Tamil Nadu, India',
        coordinates: '13.1107° N, 80.1080° E',
        capturedAt: '12 Mar 2024, 10:24 AM',
      ),
      _SiteVisitPhoto(
        assetPath: 'assets/images/construction2.png',
        location: 'Tiruvallur, Tamil Nadu, India',
        coordinates: '13.1803° N, 79.9006° E',
        capturedAt: '14 Mar 2024, 04:17 PM',
        favorite: true,
      ),
      _SiteVisitPhoto(
        assetPath: 'assets/images/construction3.png',
        location: 'Chennai, Tamil Nadu, India',
        coordinates: '13.0827° N, 80.2707° E',
        capturedAt: '15 Mar 2024, 09:03 AM',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.folder_rounded,
                  size: 21,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Site Visit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '12 photos',
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Saved to gallery',
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 2.15,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < photos.length; index++) ...[
                  if (index != 0) const SizedBox(width: 7),
                  Expanded(child: _buildPhotoPreview(photos[index])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(_SiteVisitPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            photo.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: AppColors.mutedSurface,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${photo.location}\n'
                      '${photo.coordinates}\n'
                      '${photo.capturedAt}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (photo.favorite)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: AppColors.neutral700.withValues(alpha: 0.76),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: AppColors.red,
                ),
              ),
            ),
        ],
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
        color: AppColors.surface,
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
              color: AppColors.primarySurface,
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

class _SiteVisitPhoto {
  const _SiteVisitPhoto({
    required this.assetPath,
    required this.location,
    required this.coordinates,
    required this.capturedAt,
    this.favorite = false,
  });

  final String assetPath;
  final String location;
  final String coordinates;
  final String capturedAt;
  final bool favorite;
}
