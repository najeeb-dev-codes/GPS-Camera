import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import 'interactive_location_map.dart';

class PhotoLocationPanel extends StatelessWidget {
  const PhotoLocationPanel({
    super.key,
    required this.location,
    required this.stampData,
  });

  final String location;
  final GpsStampData stampData;

  @override
  Widget build(BuildContext context) {
    final secondaryLocation = <String?>[
      stampData.postalCode,
      stampData.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');

    return Column(
      key: const ValueKey<String>('location-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.location_on_outlined,
                size: 19,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (secondaryLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondaryLocation,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: InteractiveLocationMap(
              latitude: stampData.latitude,
              longitude: stampData.longitude,
            ),
          ),
        ),
        const SizedBox(height: 10),
        CoordinateInfoRow(
          label: 'Coordinates',
          value: stampData.coordinates ??
              _formatCoordinates(
                stampData.latitude,
                stampData.longitude,
              ),
        ),
      ],
    );
  }

  String _formatCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return '—';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
