






import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/widgets.dart';

/// Uses the same responsive stamp layout in live camera and capture preview.
class ResponsiveCameraStamp extends StatelessWidget {
  const ResponsiveCameraStamp({
    super.key,
    required this.data,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.rotateWithDevice = false,
  });

  final GpsStampData data;
  final DeviceOrientation deviceOrientation;
  final bool rotateWithDevice;

  int get _quarterTurns {
    if (!rotateWithDevice) return 0;

    switch (deviceOrientation) {
      case DeviceOrientation.landscapeLeft:
        return 1;
      case DeviceOrientation.landscapeRight:
        return 3;
      case DeviceOrientation.portraitDown:
        return 2;
      case DeviceOrientation.portraitUp:
        return 0;
    }
  }

  Alignment get _alignment {
    if (!rotateWithDevice) return Alignment.bottomLeft;

    switch (deviceOrientation) {
      case DeviceOrientation.landscapeLeft:
        return Alignment.centerLeft;
      case DeviceOrientation.landscapeRight:
        return Alignment.centerRight;
      case DeviceOrientation.portraitDown:
        return Alignment.topRight;
      case DeviceOrientation.portraitUp:
        return Alignment.bottomLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = rotateWithDevice &&
            (deviceOrientation == DeviceOrientation.landscapeLeft ||
                deviceOrientation == DeviceOrientation.landscapeRight);

        // Keep the original live-camera stamp size, but anchor it explicitly
        // to the true bottom edge of the visible camera frame. Positioned is
        // important for the centered 1:1 frame because it avoids the stamp
        // appearing above the frame's bottom edge.
        if (!isLandscape &&
            deviceOrientation == DeviceOrientation.portraitUp) {
          const portraitInset = 10.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: portraitInset,
                right: portraitInset,
                bottom: portraitInset,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: GpsStampOverlay(
                      data: data,
                      mapThumbnail: MapPreviewThumbnail(
                        size: 86,
                        latitude: data.latitude,
                        longitude: data.longitude,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final inset = isLandscape ? 16.0 : 10.0;
        final mapSize = isLandscape ? 48.0 : 40.0;
        final availableWidth = isLandscape
            ? constraints.maxHeight - (inset * 2)
            : constraints.maxWidth - (inset * 2);
        final maximumWidth = availableWidth.clamp(0.0, 560.0).toDouble();

        return Align(
          alignment: _alignment,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: RotatedBox(
              quarterTurns: _quarterTurns,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maximumWidth),
                child: GpsStampOverlay(
                  data: data,
                  mapThumbnail: MapPreviewThumbnail(
                    size: mapSize * 2.15,
                    latitude: data.latitude,
                    longitude: data.longitude,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
  
