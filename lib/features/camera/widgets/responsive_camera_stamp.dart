import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/app_settings_service.dart';
import '../../../shared/widgets/widgets.dart';
import 'stamp_layout_metrics.dart';

/// Responsive live-camera stamp.
///
/// The camera UI stays portrait-locked. Only this bounded stamp canvas rotates
/// with the physical device. Map, typography, padding and card thickness scale
/// together, preventing a large map with tiny landscape text.
class ResponsiveCameraStamp extends StatelessWidget {
  const ResponsiveCameraStamp({
    super.key,
    required this.data,
    this.templateIndex = 0,
    this.deviceOrientation = DeviceOrientation.portraitUp,
    this.rotateWithDevice = false,
  });

  final GpsStampData data;
  final int templateIndex;
  final DeviceOrientation deviceOrientation;
  final bool rotateWithDevice;

  bool get _isLandscape => rotateWithDevice &&
      (deviceOrientation == DeviceOrientation.landscapeLeft ||
          deviceOrientation == DeviceOrientation.landscapeRight);

  int get _quarterTurns {
    if (!rotateWithDevice) return 0;
    return switch (deviceOrientation) {
      DeviceOrientation.landscapeLeft => 1,
      DeviceOrientation.landscapeRight => 3,
      DeviceOrientation.portraitDown => 2,
      DeviceOrientation.portraitUp => 0,
    };
  }

  Alignment get _fixedAlignment {
    if (!rotateWithDevice) return Alignment.bottomCenter;
    return switch (deviceOrientation) {
      DeviceOrientation.landscapeLeft => Alignment.centerLeft,
      DeviceOrientation.landscapeRight => Alignment.centerRight,
      DeviceOrientation.portraitDown => Alignment.topCenter,
      DeviceOrientation.portraitUp => Alignment.bottomCenter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final style = settings.stampStyleFor(templateIndex);
          final landscape = _isLandscape;
          final longAxisSize =
              landscape ? constraints.maxHeight : constraints.maxWidth;
          final inset = StampLayoutMetrics.horizontalInset(longAxisSize);

          // Before rotation, width is the long edge of the displayed stamp.
          final availableLongEdge = landscape
              ? constraints.maxHeight - (inset * 2)
              : constraints.maxWidth - (inset * 2);
          final longEdge = (math.max(0.0, availableLongEdge) *
                  (style.size / 90).clamp(0.45, 1.0))
              .toDouble();

          final availableShortEdge = landscape
              ? constraints.maxWidth - (inset * 2)
              : constraints.maxHeight - (inset * 2);
          final sizeFactor =
              (style.size / 90).clamp(0.45, 1.0).toDouble();
          final desiredThickness = (landscape
                  ? math.min(
                      availableLongEdge * 0.16,
                      availableShortEdge * 0.29,
                    )
                  : StampLayoutMetrics.portraitStampHeight(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    )) *
              sizeFactor;
          final minimumThickness = landscape ? 24.0 : desiredThickness;
          final thickness = desiredThickness
              .clamp(
                math.min(minimumThickness, availableShortEdge),
                availableShortEdge,
              )
              .toDouble();

          if (longEdge <= 0 || thickness <= 0) {
            return const SizedBox.shrink();
          }

          final referenceWidth = landscape ? 520.0 : 360.0;
          final stamp = SizedBox(
            width: longEdge,
            height: thickness,
            child: FittedBox(
              fit: landscape ? BoxFit.contain : BoxFit.fill,
              alignment: Alignment.center,
              child: SizedBox(
                width: referenceWidth,
                child: GpsStampTemplateOverlay(
                  data: data,
                  templateIndex: templateIndex,
                  compact: true,
                  mapSize: landscape ? 52 : 54,
                ),
              ),
            ),
          );

          return Padding(
            padding: EdgeInsets.all(inset),
            child: Align(
              alignment: _fixedAlignment,
              child: RotatedBox(
                quarterTurns: _quarterTurns,
                child: stamp,
              ),
            ),
          );
        },
      ),
    );
  }
}
