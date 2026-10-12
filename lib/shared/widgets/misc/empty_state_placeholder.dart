import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/app_primary_button.dart';

/// Generic empty-state view: icon, title, description, optional CTA.
///
/// Use for "No recent captures yet", empty Gallery, empty Projects list,
/// no search results, etc.
class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.titleColor,
    this.ctaLabel,
    this.onCtaTap,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Color? titleColor;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.neutral400),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.h3.copyWith(color: titleColor),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (ctaLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: ctaLabel!, onPressed: onCtaTap, expand: false),
          ],
        ],
      ),
    );
  }
}
