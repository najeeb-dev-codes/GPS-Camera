


import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Photo thumbnail with an optional title + location + timestamp caption.
///
/// Used in "Recent Captures" (Home), Gallery grid, and Stamp Template
/// preview tiles. Caption is up to 3 lines: [titleLabel] (bold, e.g. the
/// capture/project name), [locationLabel] (address), [timestampLabel]
/// (date/time) — any of the three can be omitted.
class PhotoThumbnailCard extends StatelessWidget {
  const PhotoThumbnailCard({
    super.key,
    required this.imageProvider,
    this.titleLabel,
    this.locationLabel,
    this.timestampLabel,
    this.selected = false,
    this.showSelectionCheck = false,
    this.onTap,
    this.trailing,
  });

  final ImageProvider imageProvider;

  /// Bold heading line, e.g. "Site Inspection". Shown above [locationLabel].
  final String? titleLabel;
  final String? locationLabel;
  final String? timestampLabel;

  /// Highlights the tile border (e.g. selected template, selected photo).
  final bool selected;

  /// Shows a checkmark badge in the top-right corner when [selected].
  final bool showSelectionCheck;

  final VoidCallback? onTap;

  /// Optional overlay in the top-right corner (e.g. multi-select checkbox).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    decoration: BoxDecoration(
                      border: selected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      // Graceful fallback instead of a broken-image
                      // widget/crash overlay when an asset is missing —
                      // relevant while real capture photos aren't wired
                      // up yet.
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.neutral100,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.neutral400,
                          size: AppSizes.iconLg,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showSelectionCheck && selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.check, size: 12, color: AppColors.white),
                    ),
                  ),
                if (trailing != null) Positioned(top: 6, right: 6, child: trailing!),
              ],
            ),
          ),
          if (titleLabel != null || locationLabel != null || timestampLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            if (titleLabel != null)
              Text(
                titleLabel!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (locationLabel != null)
              Text(
                locationLabel!,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (timestampLabel != null)
              Text(
                timestampLabel!,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ],
      ),
    );
  }
}