import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The pin/camera logo mark, used on Welcome, About & Help, and anywhere
/// else the app icon appears in-app.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 96, this.backgroundColor});

  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.location_on,
        size: size * 0.55,
        color: AppColors.primary,
      ),
    );
  }
}
