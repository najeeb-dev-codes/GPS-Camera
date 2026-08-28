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
    final id = capturedAt.microsecondsSinceEpoch;
    final output = File(
      '${temporaryDirectory.path}/GPSCamera_Report_$id.pdf',
    );

    await output.writeAsBytes(await document.save(), flush: true);

    if (!await output.exists() || await output.length() == 0) {
      throw Exception('Unable to create the PDF report.');
    }

    return output;
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
