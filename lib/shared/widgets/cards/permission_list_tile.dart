import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

enum PermissionState { unknown, allowed, denied, required, recommended }

/// Row for a single permission: icon, title, subtitle, trailing status.
///
/// Used on Permission Center and the Permissions Enabled summary screen.
class PermissionListTile extends StatelessWidget {
  const PermissionListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.state = PermissionState.unknown,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final PermissionState state;
  final VoidCallback? onTap;

  ({String label, Color color})? get _statusChip => switch (state) {
        PermissionState.allowed => (label: 'Allowed', color: AppColors.success),
        PermissionState.denied => (label: 'Denied', color: AppColors.error),
        PermissionState.required => (label: 'Required', color: AppColors.error),
        PermissionState.recommended => (label: 'Recommended', color: AppColors.warning),
        PermissionState.unknown => null,
      };

  @override
  Widget build(BuildContext context) {
    final chip = _statusChip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (chip != null)
              Text(
                chip.label,
                style: AppTypography.caption.copyWith(
                  color: chip.color,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
