





import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Square icon + label tile used in "Quick Actions" grids (Home, Quick
/// Actions screen) — Camera / Templates / Projects.
///
/// Renders as its own bordered card (matches the mockup — each action is a
/// visually separate tile, not a bare icon+label). [iconColor] /
/// [iconBackgroundColor] let each action use a distinct accent (e.g. blue
/// Camera, orange Templates, blue Projects) while defaulting to the
/// standard primary tint if omitted.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Icon tint. Defaults to [AppColors.primary].
  final Color? iconColor;

  /// Icon chip background. Defaults to [AppColors.primarySurface].
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? AppColors.primary;
    final tintBg = iconBackgroundColor ?? AppColors.primarySurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.thumbnailSm,
              height: AppSizes.thumbnailSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tintBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: tint, size: AppSizes.iconMd),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}