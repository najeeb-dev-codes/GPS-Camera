import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../inputs/app_toggle.dart';

/// Label (+ optional subtitle) with a trailing switch.
///
/// Used for Notifications, Offline Capture, Privacy & Security toggles,
/// and the "Visible fields" checkboxes group (as a variant).
class ToggleSettingRow extends StatelessWidget {
  const ToggleSettingRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMd, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.caption),
              ],
            ),
          ),
          AppToggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
