import 'package:flutter/material.dart';

/// Shared responsive measurements for the camera stamp and signature label.
///
/// Keeping these calculations in one place ensures the live camera, capture
/// preview and saved image always use the same proportions.
abstract final class StampLayoutMetrics {
  static double horizontalInset(double imageWidth) => imageWidth * 0.05;

  static double labelHeight(double imageHeight) {
    return (imageHeight * 0.075).clamp(42.0, 76.0).toDouble();
  }

  /// In portrait, the stamp is exactly 3% taller than the signature label.
  static double portraitStampHeight(Size imageSize) {
    return labelHeight(imageSize.height) * 1.03;
  }
}
