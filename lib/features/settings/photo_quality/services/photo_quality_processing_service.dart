import 'dart:io';
import 'dart:isolate';
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
    // Decode, enhancement and PNG encoding are the most expensive operations.
    // Keep them off the UI isolate so the Save Photo To screen remains smooth.
    final capabilitiesFuture = PhotoQualityCapabilityService.read();
    final preparedFuture = compute(
      _preparePixelsInBackground,
      <String, Object>{
        'bytes': TransferableTypedData.fromList(<Uint8List>[stampedPngBytes]),
        'hdr': settings.hdrCapture,
        'autoEnhance': settings.autoEnhance,
        'pngLevel': settings.watermarkCompression.pngLevel,
      },
    );

    final prepared = await preparedFuture;
    final capabilities = await capabilitiesFuture;
    final pngForEncoding =
        (prepared['bytes']! as TransferableTypedData)
            .materialize()
            .asUint8List();
    final outputWidth = prepared['width']! as int;
    final outputHeight = prepared['height']! as int;
    var actualFormat = settings.format;

    if (actualFormat == PhotoImageFormatOption.heic &&
        !capabilities.heicSupported) {
      actualFormat = PhotoImageFormatOption.jpeg;
    }

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
        width: outputWidth,
        height: outputHeight,
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

Future<Map<String, Object>> _preparePixelsInBackground(
  Map<String, Object> request,
) async {
  final stampedBytes = (request['bytes']! as TransferableTypedData)
      .materialize()
      .asUint8List();
  final decoded = img.decodeImage(stampedBytes);
  if (decoded == null) {
    throw Exception('Unable to decode stamped photo.');
  }

  img.Image working = decoded;
  if (request['hdr']! as bool) {
    working = img.adjustColor(
      working,
      contrast: 1.10,
      saturation: 1.05,
      exposure: 0.07,
      gamma: 0.98,
    );
  }
  if (request['autoEnhance']! as bool) {
    working = img.adjustColor(
      working,
      contrast: 1.04,
      saturation: 1.03,
      brightness: 1.015,
    );
  }

  final pngBytes = Uint8List.fromList(
    img.encodePng(working, level: request['pngLevel']! as int),
  );
  return <String, Object>{
    'bytes': TransferableTypedData.fromList(<Uint8List>[pngBytes]),
    'width': working.width,
    'height': working.height,
  };
}
