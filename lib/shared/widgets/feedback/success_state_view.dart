import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Big green checkmark + title + subtitle.
///
/// Used for "Photo Saved", "Permissions Enabled", "Template applied
/// successfully", "Project Created".
class SuccessStateView extends StatelessWidget {
  const SuccessStateView({
    super.key,
    required this.title,
    this.subtitle,
    this.iconSize = 72,
  });

  final String title;
  final String? subtitle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: AppColors.white, size: iconSize * 0.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.h1,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
