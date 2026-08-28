





import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Static OpenStreetMap thumbnail used inside the GPS stamp.
///
/// It uses the same map layer as Photo Details but has no gestures and does
/// not show latitude/longitude text over the map.
class MapPreviewThumbnail extends StatelessWidget {
  const MapPreviewThumbnail({
    super.key,
    this.size = 44,
    this.latitude,
    this.longitude,
    this.pinColor,
    this.borderRadius,
  });

  final double size;
  final double? latitude;
  final double? longitude;
  final Color? pinColor;
  final BorderRadius? borderRadius;

  bool get _hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;

    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);

    if (!_hasValidCoordinates) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          color: const Color(0xFFE7EDF5),
          alignment: Alignment.center,
          child: Icon(
            Icons.location_off_rounded,
            color: AppColors.textSecondary,
            size: size * 0.38,
          ),
        ),
      );
    }

    final capturePoint = LatLng(latitude!, longitude!);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: capturePoint,
                initialZoom: 16,
                minZoom: 16,
                maxZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gps_camera_app',
                  maxNativeZoom: 19,
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_rounded,
                color: pinColor ?? AppColors.error,
                size: size * 0.38,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 2,
              bottom: 1,
              child: Text(
                '© OSM',
                style: TextStyle(
                  color: Colors.black87,
                  backgroundColor: Colors.white70,
                  fontSize: (size * 0.065).clamp(5.0, 8.0).toDouble(),
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
