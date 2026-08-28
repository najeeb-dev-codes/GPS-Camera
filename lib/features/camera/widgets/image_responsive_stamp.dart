



import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';

/// Responsive GPS stamp for the actual captured image.
class ImageResponsiveStamp extends StatelessWidget {
  const ImageResponsiveStamp({
    super.key,
    required this.data,
    required this.imageSize,
    this.bottomInset = 0,
  });

  final GpsStampData data;
  final Size imageSize;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return const SizedBox.shrink();
    }

    final imageWidth = imageSize.width;
    final imageHeight = imageSize.height;
    final horizontalGap = imageWidth * 0.03;
    final stampWidth = imageWidth * 0.94;
    final targetStampHeight = imageHeight * 0.18;
    final stampHeight = targetStampHeight
        .clamp(
          38.0,
          math.max(38.0, imageHeight * 0.20),
        )
        .toDouble();
    final bottomGap = (imageHeight * 0.025).clamp(4.0, 12.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: horizontalGap,
          right: horizontalGap,
          bottom: bottomGap + bottomInset,
          child: SizedBox(
            width: stampWidth,
            height: stampHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 520,
                child: GpsStampOverlay(
                  data: data,
                  mapThumbnail: MapPreviewThumbnail(
                    size: 104,
                    latitude: data.latitude,
                    longitude: data.longitude,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
