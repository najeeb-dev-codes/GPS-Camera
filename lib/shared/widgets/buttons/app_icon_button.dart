import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Small circular icon button.
///
/// Used in the live camera toolbar (flash, timer, grid, ratio, settings,
/// flip camera) and anywhere else a compact tappable icon is needed.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Highlights the button (e.g. flash currently on).
  final bool isActive;

  final Color? backgroundColor;
  final Color? iconColor;

  /// Overall diameter of the tappable circle.
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (isActive
            ? AppColors.primary
            : AppColors.neutral900.withValues(alpha: 0.35));
    final fg = iconColor ?? AppColors.white;

    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: fg, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}
