import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'photo_content_service.dart';

class PhotoPdfExportService {
  PhotoPdfExportService._();

  static Future<File> createStampedPhotoPdf({
    required ResolvedPhotoContent content,
    required DateTime capturedAt,
    String? projectName,
    int? imageWidth,
    int? imageHeight,
  }) async {
    final imageBytes = await _readPdfCompatibleImage(content);
    final image = pw.MemoryImage(imageBytes);
    final landscape = (imageWidth ?? 0) > (imageHeight ?? 0);
    final pageFormat = landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    final temporaryDirectory = await getTemporaryDirectory();
    final timestamp = _formatTimestamp(DateTime.now());
    final normalizedProjectName = _sanitizeProjectName(projectName);
    final fileName = normalizedProjectName == null
        ? 'GPSMark_$timestamp.pdf'
        : 'GPSMark_${normalizedProjectName}_$timestamp.pdf';
    final output = File('${temporaryDirectory.path}/$fileName');

    await output.writeAsBytes(await document.save(), flush: true);

    if (!await output.exists() || await output.length() == 0) {
      throw Exception('Unable to create the PDF report.');
    }

    return output;
  }

  static String? _sanitizeProjectName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final sanitized = trimmed
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? null : sanitized;
  }

  static String _formatTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year.toString().padLeft(4, '0')}'
        '${twoDigits(value.month)}'
        '${twoDigits(value.day)}_'
        '${twoDigits(value.hour)}'
        '${twoDigits(value.minute)}'
        '${twoDigits(value.second)}';
  }

  static Future<Uint8List> _readPdfCompatibleImage(
    ResolvedPhotoContent content,
  ) async {
    final lowerName = content.fileName.toLowerCase();
    final directlySupported = lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png');

    if (directlySupported) {
      return content.file.readAsBytes();
    }

    final converted = await FlutterImageCompress.compressWithFile(
      content.file.path,
      format: CompressFormat.jpeg,
      quality: 95,
    );

    if (converted == null || converted.isEmpty) {
      throw Exception(
        'This photo format could not be converted for PDF export.',
      );
    }

    return converted;
  }
}
