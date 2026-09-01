import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

class ProjectMapPanel extends StatelessWidget {
  const ProjectMapPanel({super.key, required this.photos});

  final List<CapturedPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final points = photos
        .map((photo) => _PhotoPoint.fromPhoto(photo))
        .whereType<_PhotoPoint>()
        .toList();
    if (points.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.location_off_outlined,
        title: 'No mapped photos',
        description: 'Photos with GPS coordinates will appear here.',
      );
    }

    final center = LatLng(
      points.fold<double>(0, (sum, item) => sum + item.point.latitude) /
          points.length,
      points.fold<double>(0, (sum, item) => sum + item.point.longitude) /
          points.length,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: _initialZoom(points),
            minZoom: 2,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gps_camera_app',
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: points
                  .map(
                    (item) => Marker(
                      point: item.point,
                      width: 42,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: Tooltip(
                        message: item.label,
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: AppColors.error,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
    );
  }

  double _initialZoom(List<_PhotoPoint> points) {
    if (points.length == 1) return 16;
    final latitudes = points.map((item) => item.point.latitude);
    final longitudes = points.map((item) => item.point.longitude);
    final spread = (latitudes.reduce((a, b) => a > b ? a : b) -
            latitudes.reduce((a, b) => a < b ? a : b))
        .abs()
        .clamp(0, 180)
        .toDouble();
    final lngSpread = (longitudes.reduce((a, b) => a > b ? a : b) -
            longitudes.reduce((a, b) => a < b ? a : b))
        .abs()
        .clamp(0, 360)
        .toDouble();
    final maxSpread = spread > lngSpread ? spread : lngSpread;
    if (maxSpread < 0.01) return 14;
    if (maxSpread < 0.1) return 11;
    if (maxSpread < 1) return 8;
    if (maxSpread < 10) return 5;
    return 3;
  }
}

class _PhotoPoint {
  const _PhotoPoint(this.point, this.label);

  final LatLng point;
  final String label;

  static _PhotoPoint? fromPhoto(CapturedPhoto photo) {
    final latitude = photo.stampData?.latitude;
    final longitude = photo.stampData?.longitude;
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return _PhotoPoint(LatLng(latitude, longitude), photo.location);
  }
}
