import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Segmented tab / pill selector.
///
/// Used for "All / Construction / Survey / General" (Templates) and
/// "All / Active / Archived" (Projects).
class AppTabSelector extends StatelessWidget {
  const AppTabSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.scrollable = true,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Whether the tab row scrolls horizontally (use false for 2-3 fixed
  /// tabs that should fill the width, e.g. All/Active/Archived).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: List.generate(tabs.length, (index) {
        final selected = index == selectedIndex;
      final tab = GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tabs[index],
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? AppColors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          );

      final padded = Padding(
        padding: EdgeInsets.only(right: scrollable ? AppSpacing.sm : 0),
        child: tab,
      );

      // Expanded must be a direct child of Row. Placing it below Padding
      // causes an Incorrect use of ParentDataWidget runtime exception.
      return scrollable ? padded : Expanded(child: padded);
      }),
    );

    if (!scrollable) return row;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: row,
    );
  }
}
