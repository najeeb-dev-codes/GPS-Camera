import 'package:flutter/material.dart';

import '../../core/services/sample_location_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../gallery/gallery_screen.dart';
import '../stamp_templates/stamp_templates_screen.dart';
import 'live_camera_screen.dart';

/// Save Successfully screen.
///
/// Confirms the geotagged photo was saved, shows the final stamped photo,
/// and offers Share / View in Gallery / Capture Another Photo.
class SaveSuccessScreen extends StatelessWidget {
  const SaveSuccessScreen({
    super.key,
    this.template = const StampTemplateInfo(
      label: 'Map Card',
      visibility: GpsStampFieldVisibility(),
    ),
  });

  final StampTemplateInfo template;

  void _shareImage(BuildContext context) {
    // Wire up share_plus (or platform share sheet) once available.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing photo…')),
    );
  }

  void _viewInGallery(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
      (route) => false,
    );
  }

  void _captureAnother(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LiveCameraScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = SampleLocationData.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Photo Saved',
        onBack: () => _captureAnother(context),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
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
                        const SuccessStateView(
                          title: 'Photo saved successfully',
                          subtitle: 'Your geotagged image is ready.',
                        ),

                        const SizedBox(height: 20),

                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
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
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  bottom: 10,
                                  child: GpsStampOverlay(
                                    data: data,
                                    visibility: template.visibility,
                                    dark: template.dark,
                                    compact: template.compact,
                                    mapThumbnail:
                                        const MapPreviewThumbnail(size: 34),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            data.address,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        label: 'Share Image',
                        icon: Icons.ios_share_rounded,
                        onPressed: () => _shareImage(context),
                      ),
                      const SizedBox(height: 8),
                      AppSecondaryButton(
                        label: 'View in Gallery',
                        onPressed: () => _viewInGallery(context),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _captureAnother(context),
                        child: Text(
                          'Capture Another Photo',
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