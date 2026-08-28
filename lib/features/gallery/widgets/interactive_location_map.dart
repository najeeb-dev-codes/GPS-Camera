




//! Map

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Static map used only in Photo Details.
///
/// It centers on the coordinates saved with the photo and deliberately blocks
/// pan, zoom and rotation so the section behaves like a rectangular image.
class InteractiveLocationMap extends StatelessWidget {
  const InteractiveLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.initialZoom = 16,
  });

  final double? latitude;
  final double? longitude;
  final double initialZoom;

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
    if (!_hasValidCoordinates) {
      return Container(
        color: const Color(0xFFE7EDF5),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 6),
            Text(
              'Location coordinates unavailable',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final capturePoint = LatLng(latitude!, longitude!);

    return FlutterMap(
      options: MapOptions(
        initialCenter: capturePoint,
        initialZoom: initialZoom,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gps_camera_app',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: capturePoint,
              width: 46,
              height: 54,
              alignment: Alignment.bottomCenter,
              child: const Icon(
                Icons.location_on_rounded,
                size: 44,
                color: AppColors.error,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}
