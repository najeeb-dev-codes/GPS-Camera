import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

enum AdPlacementType { banner, native, interstitial, rewarded, custom }

/// Ad slot card used across Home, Gallery, Templates, Projects, Project
/// Details.
///
/// IMPORTANT (per mockup note): never place this widget over GPS stamps,
/// photos, navigation, primary buttons, or system controls. Keep it in its
/// own dedicated slot in the layout.
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel = 'Learn More',
    this.onCtaTap,
    this.type = AdPlacementType.native,
    this.imageProvider,
  });

  final String title;
  final String? subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaTap;
  final AdPlacementType type;
  final ImageProvider? imageProvider;

  String get _tag => switch (type) {
        AdPlacementType.banner => 'Advertisement',
        AdPlacementType.native => 'Sponsored',
        AdPlacementType.interstitial => 'Advertisement',
        AdPlacementType.rewarded => 'Promoted',
        AdPlacementType.custom => 'Promoted by GeoStamp',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (imageProvider != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image(image: imageProvider!, width: 48, height: 48, fit: BoxFit.cover),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tag,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onCtaTap,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(ctaLabel, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
