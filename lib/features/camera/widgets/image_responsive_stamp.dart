import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/app_settings_service.dart';
import '../../../shared/widgets/widgets.dart';
import 'stamp_layout_metrics.dart';

/// Responsive stamp burned into the captured image.
///
/// Uses the same proportional renderer as the live camera. The complete stamp
/// scales as one unit for 1:1, 4:3, 16:9 and Full images on phones/tablets.
class ImageResponsiveStamp extends StatelessWidget {
  const ImageResponsiveStamp({
    super.key,
    required this.data,
    required this.imageSize,
    this.templateIndex = 0,
    this.bottomInset = 0,
  });

  final GpsStampData data;
  final Size imageSize;
  final int templateIndex;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return const SizedBox.shrink();
    }

    final settings = AppSettingsService.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final landscape = imageSize.width > imageSize.height;
        final style = settings.stampStyleFor(templateIndex);
        final sizeFactor = (style.size / 90).clamp(0.40, 1.0).toDouble();
        // 90% is the maximum width, preserving the required 5% side margin.
        final horizontalGap =
            StampLayoutMetrics.horizontalInset(imageSize.width);
        final baseStampWidth = imageSize.width - (horizontalGap * 2);
        final stampWidth = imageSize.width * (style.size / 100);
        final bottomGap =
            (imageSize.height * 0.025).clamp(4.0, 12.0).toDouble();
        final desiredHeight = (landscape
                ? math.min(baseStampWidth * 0.16, imageSize.height * 0.24)
                : StampLayoutMetrics.portraitStampHeight(imageSize)) *
            sizeFactor;
        final availableHeight = math.max(
          1.0,
          imageSize.height - bottomGap - bottomInset,
        );
        final stampHeight = math.min(desiredHeight, availableHeight).toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: (imageSize.width - stampWidth) / 2,
              bottom: bottomGap + bottomInset,
              width: stampWidth,
              height: stampHeight,
              child: FittedBox(
                fit: landscape ? BoxFit.contain : BoxFit.fill,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: landscape ? 520 : 360,
                  child: GpsStampTemplateOverlay(
                    data: data,
                    templateIndex: templateIndex,
                    compact: true,
                    mapSize: landscape ? 52 : 54,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
