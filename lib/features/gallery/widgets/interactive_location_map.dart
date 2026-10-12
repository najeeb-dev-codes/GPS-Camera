import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Map used by the dedicated Photo Location screen.
///
/// The map stays centered on the captured coordinates. Dragging and rotation
/// are disabled. Zoom is available only through the explicit controls and is
/// limited to a city-level range so users cannot zoom out to a world view.
class InteractiveLocationMap extends StatefulWidget {
  const InteractiveLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.initialZoom = 16,
  });

  final double? latitude;
  final double? longitude;
  final double initialZoom;

  @override
  State<InteractiveLocationMap> createState() =>
      _InteractiveLocationMapState();
}

class _InteractiveLocationMapState extends State<InteractiveLocationMap> {
  static const double _minimumZoom = 12;
  static const double _maximumZoom = 19;

  final MapController _mapController = MapController();

  bool get _hasValidCoordinates {
    final latitude = widget.latitude;
    final longitude = widget.longitude;

    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidCoordinates) {
      return Container(
        color: AppColors.mutedSurface,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(
              Icons.location_off_outlined,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
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

    final capturePoint = LatLng(
      widget.latitude!,
      widget.longitude!,
    );
    final initialZoom = widget.initialZoom
        .clamp(_minimumZoom, _maximumZoom)
        .toDouble();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: capturePoint,
            initialZoom: initialZoom,
            minZoom: _minimumZoom,
            maxZoom: _maximumZoom,
            interactionOptions: const InteractionOptions(
              // Keep the map fixed in place, but allow two-finger pinch zoom
              // and double-tap zoom in addition to the +/- controls.
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.raiyaan_infotech.gpsmark',
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
        ),
        Positioned(
          right: 12,
          bottom: 42,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                  icon: const Icon(Icons.add_rounded),
                ),
                const Divider(height: 1),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                  icon: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _zoomBy(double delta) {
    final currentZoom = _mapController.camera.zoom;
    final nextZoom =
        (currentZoom + delta).clamp(_minimumZoom, _maximumZoom).toDouble();

    if (nextZoom == currentZoom) return;

    _mapController.move(
      _mapController.camera.center,
      nextZoom,
    );
  }
}
