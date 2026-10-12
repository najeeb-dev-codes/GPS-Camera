import 'dart:io';

import 'package:flutter/foundation.dart';
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
    bool mirrorHorizontally = false,
  }) async {
    if (!await File(sourcePath).exists()) {
      throw Exception('Captured camera image was not found.');
    }

    final tempDirectory = await getTemporaryDirectory();
    final id = DateTime.now().microsecondsSinceEpoch;
    final outputPath =
        '${tempDirectory.path}/gps_camera_normalized_$id.jpg';

    // Full-resolution decode/rotation is CPU intensive. Running it outside the
    // UI isolate keeps Preview responsive and lets it display one clear loader.
    final result = await compute(
      _normalizeInBackground,
      <String, Object>{
        'sourcePath': sourcePath,
        'outputPath': outputPath,
        'orientation': deviceOrientation.name,
        'mirror': mirrorHorizontally,
      },
    );

    return NormalizedCapturedImage(
      path: outputPath,
      width: result['width']! as int,
      height: result['height']! as int,
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

Future<Map<String, Object>> _normalizeInBackground(
  Map<String, Object> request,
) async {
  final source = File(request['sourcePath']! as String);
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    throw Exception('Unable to decode captured camera image.');
  }

  img.Image normalized = img.bakeOrientation(decoded);
  normalized = CapturedImageOrientationService._rotateForCapturedDeviceOrientation(
    normalized,
    DeviceOrientation.values.byName(request['orientation']! as String),
  );

  if (request['mirror']! as bool) {
    normalized = img.flipHorizontal(normalized);
  }

  // JPEG is substantially faster and smaller than the previous temporary PNG.
  // The final export still follows the user's selected format and quality.
  await File(request['outputPath']! as String).writeAsBytes(
    img.encodeJpg(normalized, quality: 94),
    flush: false,
  );

  return <String, Object>{
    'width': normalized.width,
    'height': normalized.height,
  };
}
