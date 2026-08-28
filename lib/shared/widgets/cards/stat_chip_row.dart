import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

class StatChipItem {
  const StatChipItem({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;
}

/// Row of stat "chips", e.g. Photos / Locations / Storage on Project
/// Details, or Photos/Locations/Members/Storage overview.
class StatChipRow extends StatelessWidget {
  const StatChipRow({super.key, required this.items});

  final List<StatChipItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: [
                  Icon(item.icon, color: AppColors.primary, size: AppSizes.iconMd),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.value,
                    style: AppTypography.h3,
                  ),
                  Text(
                    item.label,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
