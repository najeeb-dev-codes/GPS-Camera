import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Label with a trailing dropdown value, e.g. "Location source: Device GPS",
/// "Map Type: Standard", "Aspect Ratio: 4:3".
class DropdownSettingRow<T> extends StatelessWidget {
  const DropdownSettingRow({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  final String title;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  /// Converts an item to display text. Defaults to `toString()`.
  final String Function(T item)? itemLabel;

  String _labelOf(T item) => itemLabel?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTypography.bodyMedium),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral400),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(_labelOf(item)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
