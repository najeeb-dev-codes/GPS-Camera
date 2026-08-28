



import 'package:native_exif/native_exif.dart';

import '../../../../shared/widgets/widgets.dart';

class PhotoQualityMetadataService {
  PhotoQualityMetadataService._();

  static const _copyableTags = <String>{
    'Make',
    'Model',
    'DateTime',
    'DateTimeOriginal',
    'DateTimeDigitized',
    'ExposureTime',
    'FNumber',
    'ISOSpeedRatings',
    'PhotographicSensitivity',
    'FocalLength',
    'Flash',
    'WhiteBalance',
  };

  static Future<void> apply({
    required String originalPath,
    required String targetPath,
    required GpsStampData stampData,
    required DateTime capturedAt,
    required bool preserveOriginal,
    required bool embedGps,
  }) async {
    Exif? sourceExif;
    Exif? targetExif;

    try {
      targetExif = await Exif.fromPath(targetPath);

      // The target image pixels are already normalized/upright. Never copy the
      // camera JPEG Orientation tag onto this file or gallery viewers will
      // rotate the finished photo a second time.
      try {
        await targetExif.writeAttribute('Orientation', '1');
      } catch (_) {}

      if (preserveOriginal) {
        sourceExif = await Exif.fromPath(originalPath);
        final sourceAttributes = await sourceExif.getAttributes() ?? {};

        for (final entry in sourceAttributes.entries) {
          if (!_copyableTags.contains(entry.key)) continue;
          try {
            await targetExif.writeAttribute(entry.key, entry.value.toString());
          } catch (_) {
            // Some camera/device EXIF tags are read-only. Ignore them safely.
          }
        }
      }

      try {
        await targetExif.writeAttribute(
          'DateTimeOriginal',
          _formatExifDate(capturedAt),
        );
      } catch (_) {}

      if (embedGps &&
          stampData.latitude != null &&
          stampData.longitude != null) {
        final latitude = stampData.latitude!;
        final longitude = stampData.longitude!;

        final gps = <String, Object>{
          'GPSLatitude': latitude.abs().toString(),
          'GPSLatitudeRef': latitude >= 0 ? 'N' : 'S',
          'GPSLongitude': longitude.abs().toString(),
          'GPSLongitudeRef': longitude >= 0 ? 'E' : 'W',
        };

        final altitude = _readAltitude(stampData.altitude);
        if (altitude != null) {
          gps['GPSAltitude'] = altitude.abs().toString();
          gps['GPSAltitudeRef'] = altitude < 0 ? '1' : '0';
        }

        await targetExif.writeAttributes(gps);
      }
    } finally {
      await sourceExif?.close();
      await targetExif?.close();
    }
  }

  static double? _readAltitude(String? value) {
    if (value == null) return null;
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  static String _formatExifDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}:${two(value.month)}:${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
