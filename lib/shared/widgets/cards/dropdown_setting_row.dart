import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownWidth =
            (constraints.maxWidth * 0.48).clamp(120.0, 260.0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: dropdownWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: value,
                      onChanged: onChanged,
                      isExpanded: true,
                      isDense: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      dropdownColor: colors.surfaceContainerHighest,
                      menuMaxHeight: 320,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.primary,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                      selectedItemBuilder: (context) => items
                          .map(
                            (item) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _labelOf(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      items: items
                          .map(
                            (item) => DropdownMenuItem<T>(
                              value: item,
                              child: Text(
                                _labelOf(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
