import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared responsive measurements for the camera stamp and signature label.
///
/// Keeping these calculations in one place ensures the live camera, capture
/// preview and saved image always use the same proportions.
abstract final class StampLayoutMetrics {
  static double horizontalInset(double imageWidth) => imageWidth * 0.05;

  static double labelHeight(double imageHeight) {
    return (imageHeight * 0.09).clamp(48.0, 84.0).toDouble();
  }

  /// Base portrait stamp height shared with the signature label.
  static double portraitStampHeight(Size imageSize) {
    return labelHeight(imageSize.height);
  }

  static double verticalContentInset(double stampHeight) {
    return (stampHeight * 0.02).clamp(2.0, 6.0).toDouble();
  }

  /// Keeps map thumbnails square inside the available stamp height.
  static double squareElementSize(double stampHeight) {
    final verticalInset = verticalContentInset(stampHeight);
    return (stampHeight - (verticalInset * 2) - 2)
        .clamp(0.0, stampHeight)
        .toDouble();
  }

  static double portraitTemplateHeight(Size imageSize, int templateIndex) {
    return portraitStampHeight(imageSize);
  }

  /// Keeps landscape stamps shorter without affecting portrait sizing.
  static double landscapeStampHeight(
    double availableLongEdge,
    double availableShortEdge,
  ) {
    return math.min(
      availableLongEdge * 0.13,
      availableShortEdge * 0.23,
    );
  }
}
