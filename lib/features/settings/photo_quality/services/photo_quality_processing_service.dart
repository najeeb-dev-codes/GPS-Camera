import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../../shared/widgets/widgets.dart';
import '../models/photo_capture_metadata.dart';
import '../models/photo_processing_result.dart';
import '../models/photo_quality_settings.dart';
import 'photo_quality_capability_service.dart';
import 'photo_quality_metadata_service.dart';

class PhotoQualityProcessingService {
  PhotoQualityProcessingService._();

  static Future<PhotoProcessingResult> process({
    required Uint8List stampedPngBytes,
    required String originalCameraPath,
    required GpsStampData stampData,
    required DateTime capturedAt,
    required PhotoQualitySettings settings,
  }) async {
    final decoded = img.decodeImage(stampedPngBytes);
    if (decoded == null) {
      throw Exception('Unable to decode stamped photo.');
    }

    img.Image working = decoded;

    // Functional single-frame HDR tone enhancement. The Flutter camera plugin
    // does not expose universal native multi-frame HDR controls on Android.
    if (settings.hdrCapture) {
      working = img.adjustColor(
        working,
        contrast: 1.10,
        saturation: 1.05,
        exposure: 0.07,
        gamma: 0.98,
      );
    }

    if (settings.autoEnhance) {
      working = img.adjustColor(
        working,
        contrast: 1.04,
        saturation: 1.03,
        brightness: 1.015,
      );
    }

    final capabilities = await PhotoQualityCapabilityService.read();
    var actualFormat = settings.format;

    if (actualFormat == PhotoImageFormatOption.heic &&
        !capabilities.heicSupported) {
      actualFormat = PhotoImageFormatOption.jpeg;
    }

    final pngForEncoding = Uint8List.fromList(
      img.encodePng(
        working,
        level: settings.watermarkCompression.pngLevel,
      ),
    );

    Uint8List finalBytes;

    if (actualFormat == PhotoImageFormatOption.png) {
      finalBytes = pngForEncoding;
    } else if (actualFormat == PhotoImageFormatOption.jpeg) {
      finalBytes = await FlutterImageCompress.compressWithList(
        pngForEncoding,
        quality: settings.effectiveJpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
    } else {
      try {
        finalBytes = await FlutterImageCompress.compressWithList(
          pngForEncoding,
          quality: settings.effectiveJpegQuality,
          format: CompressFormat.heic,
          keepExif: false,
        );
      } catch (error) {
        debugPrint('HEIC encode unavailable, falling back to JPEG: $error');
        actualFormat = PhotoImageFormatOption.jpeg;
        finalBytes = await FlutterImageCompress.compressWithList(
          pngForEncoding,
          quality: settings.effectiveJpegQuality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );
      }
    }

    final tempDirectory = await getTemporaryDirectory();
    final id = capturedAt.microsecondsSinceEpoch;
    final outputFile = File(
      '${tempDirectory.path}/gps_photo_quality_$id.${actualFormat.extension}',
    );

    await outputFile.writeAsBytes(finalBytes, flush: true);

    var exifPreserved = false;
    var gpsEmbedded = false;

    if (capabilities.exifWritingSupported &&
        (settings.preserveExifMetadata || settings.embedGpsInExif)) {
      try {
        await PhotoQualityMetadataService.apply(
          originalPath: originalCameraPath,
          targetPath: outputFile.path,
          stampData: stampData,
          capturedAt: capturedAt,
          preserveOriginal: settings.preserveExifMetadata,
          embedGps: settings.embedGpsInExif,
        );
        exifPreserved = settings.preserveExifMetadata;
        gpsEmbedded = settings.embedGpsInExif &&
            stampData.latitude != null &&
            stampData.longitude != null;
      } catch (error) {
        // Metadata failure must never destroy an otherwise valid captured image.
        debugPrint('EXIF write skipped: $error');
      }
    }

    final fileSize = await outputFile.length();

    return PhotoProcessingResult(
      path: outputFile.path,
      metadata: PhotoCaptureMetadata(
        width: working.width,
        height: working.height,
        fileSizeBytes: fileSize,
        format: actualFormat.label,
        jpegQuality: actualFormat == PhotoImageFormatOption.png
            ? 100
            : settings.effectiveJpegQuality,
        resolution: settings.resolution.label,
        hdrApplied: settings.hdrCapture,
        autoEnhanceApplied: settings.autoEnhance,
        exifPreserved: exifPreserved,
        gpsEmbedded: gpsEmbedded,
      ),
    );
  }
}
