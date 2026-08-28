import 'package:camera/camera.dart';

import '../models/photo_quality_settings.dart';

class PhotoQualityCameraService {
  PhotoQualityCameraService._();

  static ResolutionPreset resolutionPreset(PhotoResolutionOption value) {
    return switch (value) {
      PhotoResolutionOption.highestAvailable => ResolutionPreset.max,
      PhotoResolutionOption.high => ResolutionPreset.high,
      PhotoResolutionOption.medium => ResolutionPreset.medium,
      PhotoResolutionOption.low => ResolutionPreset.low,
    };
  }
}
