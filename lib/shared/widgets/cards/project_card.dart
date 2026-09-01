import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Project row/card: thumbnail, name, [location] (optional), photo count,
/// status chip (optional).
///
/// Used on Home ("Recent Project" — just name + photo count, no location,
/// with a trailing chevron via [showChevron]), Projects list, and Project
/// Details header cards.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.name,
    required this.photoCount,
    this.location,
    this.imageProvider,
    this.statusLabel,
    this.statusColor,
    this.updatedLabel,
    this.onTap,
    this.trailing,
    this.showChevron = false,
  });

  final String name;
  final int photoCount;

  /// Optional — omit for a compact card (e.g. Home's "Recent Project").
  final String? location;
  final ImageProvider? imageProvider;

  /// e.g. "Active" / "Archived".
  final String? statusLabel;
  final Color? statusColor;

  /// e.g. "Updated today", "Updated 2 days ago".
  final String? updatedLabel;

  final VoidCallback? onTap;

  /// Trailing widget, e.g. a "..." overflow menu button.
  final Widget? trailing;

  /// Shows a trailing ">" chevron (ignored if [trailing] is set).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 48,
                height: 48,
                color: AppColors.neutral100,
                child: imageProvider != null
                    ? Image(
                        image: imageProvider!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.neutral400,
                        ),
                      )
                    : const Icon(Icons.folder_copy_outlined, color: AppColors.neutral400),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      location!,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    [
                      '$photoCount photos',
                      if (updatedLabel != null) updatedLabel!,
                    ].join(' • '),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: (statusColor ?? AppColors.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusLabel!,
                  style: AppTypography.caption.copyWith(
                    color: statusColor ?? AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ] else if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ],
        ),
      ),
    );
  }
}