import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

enum GpsStatus { good, warning, error }

/// Small status pill, e.g. "Location verified", "GPS Ready ± 4m",
/// "GPS Signal Excellent • ± 4 m".
class GpsStatusBadge extends StatelessWidget {
  const GpsStatusBadge({
    super.key,
    required this.label,
    this.status = GpsStatus.good,
    this.icon,
  });

  final String label;
  final GpsStatus status;

  /// Override the default status icon (defaults to check/warning circle).
  final IconData? icon;

  Color get _color => switch (status) {
        GpsStatus.good => AppColors.success,
        GpsStatus.warning => AppColors.warning,
        GpsStatus.error => AppColors.error,
      };

  IconData get _icon =>
      icon ??
      switch (status) {
        GpsStatus.good => Icons.check_circle,
        GpsStatus.warning => Icons.error_outline,
        GpsStatus.error => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
