import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Normalizes a camera image into real upright pixels before it reaches
/// Capture Preview.
///
/// Some Android devices keep the Flutter activity portrait-locked even while
/// the phone is physically landscape. In that situation the camera file can
/// still be portrait-shaped with sideways content. The physical orientation
/// captured at shutter time is therefore used as a second source of truth.
class NormalizedCapturedImage {
  const NormalizedCapturedImage({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final int width;
  final int height;

  double get aspectRatio {
    if (width <= 0 || height <= 0) return 4 / 3;
    return width / height;
  }
}

class CapturedImageOrientationService {
  CapturedImageOrientationService._();

  static Future<NormalizedCapturedImage> normalize({
    required String sourcePath,
    required DeviceOrientation deviceOrientation,
  }) async {
    final source = File(sourcePath);

    if (!await source.exists()) {
      throw Exception('Captured camera image was not found.');
    }

    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('Unable to decode captured camera image.');
    }

    // First bake any valid EXIF orientation into the actual pixels.
    img.Image normalized = img.bakeOrientation(decoded);

    // If the activity stayed portrait-locked while the phone was physically
    // landscape, EXIF can still leave us with portrait dimensions and sideways
    // content. Rotate only when the dimensions do not already match the frozen
    // shutter-time orientation. This prevents double rotation.
    normalized = _rotateForCapturedDeviceOrientation(
      normalized,
      deviceOrientation,
    );

    final tempDirectory = await getTemporaryDirectory();
    final id = DateTime.now().microsecondsSinceEpoch;
    final output = File(
      '${tempDirectory.path}/gps_camera_normalized_$id.png',
    );

    await output.writeAsBytes(
      img.encodePng(normalized, level: 3),
      flush: true,
    );

    return NormalizedCapturedImage(
      path: output.path,
      width: normalized.width,
      height: normalized.height,
    );
  }

  static img.Image _rotateForCapturedDeviceOrientation(
    img.Image image,
    DeviceOrientation orientation,
  ) {
    final isPortraitPixels = image.height >= image.width;

    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        if (!isPortraitPixels) return image;
        // Android sensor coordinates are opposite to the physical phone
        // direction reported by the orientation stream. Rotating the other
        // way keeps the captured scene upright instead of upside down.
        return img.copyRotate(image, angle: 270);

      case DeviceOrientation.landscapeRight:
        if (!isPortraitPixels) return image;
        return img.copyRotate(image, angle: 90);

      case DeviceOrientation.portraitDown:
        return img.copyRotate(image, angle: 180);

      case DeviceOrientation.portraitUp:
        return image;
    }
  }
}
