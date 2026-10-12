import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    final row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: List.generate(tabs.length, (index) {
        final selected = index == selectedIndex;
        final tab = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: scrollable ? AppSpacing.lg : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tabs[index],
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
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
