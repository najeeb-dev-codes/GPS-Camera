import 'package:flutter/material.dart';
import 'package:gps_mark/features/gallery/widgets/interactive_location_map.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/widgets.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Open in Maps'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child:  Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InteractiveLocationMap(
                          latitude: stampData.latitude,
                          longitude: stampData.longitude,
                          initialZoom: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CoordinateInfoRow(
                      label: 'Coordinates',
                      value: stampData.coordinates ??
                          _formatCoordinates(
                            stampData.latitude,
                            stampData.longitude,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const AdBannerWidget(
              format: AdDisplayFormat.largeBanner,
              reserveSpaceWhileLoading: true,
              slotHeight: 100,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  String _formatCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return '—';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
