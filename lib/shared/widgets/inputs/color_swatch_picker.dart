import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Row of selectable color circles, e.g. Accent Color (Appearance settings,
/// Template Preview) and project Cover color picker.
class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    required this.colors,
    required this.selectedIndex,
    required this.onChanged,
    this.swatchSize = 32,
  });

  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double swatchSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(colors.length, (index) {
        final selected = index == selectedIndex;
        final color = colors[index];

        return GestureDetector(
          onTap: () => onChanged(index),
          child: Container(
            width: swatchSize,
            height: swatchSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: swatchSize * 0.5,
                    color: color.computeLuminance() > 0.5
                        ? AppColors.lightTextPrimary
                        : AppColors.white,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
