import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class PhotoQualityCapabilities {
  const PhotoQualityCapabilities({
    required this.heicSupported,
    required this.exifWritingSupported,
  });

  final bool heicSupported;
  final bool exifWritingSupported;
}

class PhotoQualityCapabilityService {
  PhotoQualityCapabilityService._();

  static Future<PhotoQualityCapabilities> read() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      return PhotoQualityCapabilities(
        heicSupported: info.version.sdkInt >= 28,
        exifWritingSupported: info.version.sdkInt >= 24,
      );
    }

    if (Platform.isIOS) {
      return const PhotoQualityCapabilities(
        heicSupported: true,
        exifWritingSupported: true,
      );
    }

    return const PhotoQualityCapabilities(
      heicSupported: false,
      exifWritingSupported: false,
    );
  }
}
