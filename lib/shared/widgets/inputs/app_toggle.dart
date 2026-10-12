import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One consistent toggle used everywhere in the app.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const double _scale = 0.80;

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scale,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: AppColors.white,
        inactiveTrackColor: AppColors.inactiveSurface,
        trackOutlineColor: WidgetStateProperty.all(AppColors.primary),
        trackOutlineWidth: WidgetStateProperty.all(2),
      ),
    );
  }
}
