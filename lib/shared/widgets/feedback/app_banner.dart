import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

enum BannerTone { info, success, warning, error }

/// Inline note banner.
///
/// Covers small reassurance notes ("Location is added only when you
/// capture", "Local processing • Data stays on device") as [BannerTone.info]
/// / [BannerTone.success], and alerts ("Camera permission is required",
/// "GPS signal accuracy is ± 18 m") as [BannerTone.warning] /
/// [BannerTone.error].
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.icon,
    this.trailing,
  });

  final String message;
  final BannerTone tone;
  final IconData? icon;

  /// Optional trailing action, e.g. a "View" link.
  final Widget? trailing;

  Color get _color => switch (tone) {
        BannerTone.info => AppColors.primary,
        BannerTone.success => AppColors.success,
        BannerTone.warning => AppColors.warning,
        BannerTone.error => AppColors.error,
      };

  IconData get _icon =>
      icon ??
      switch (tone) {
        BannerTone.info => Icons.info_outline,
        BannerTone.success => Icons.verified_outlined,
        BannerTone.warning => Icons.warning_amber_rounded,
        BannerTone.error => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: AppSizes.iconSm, color: _color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
