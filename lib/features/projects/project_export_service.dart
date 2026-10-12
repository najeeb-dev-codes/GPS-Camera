import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'project_data.dart';

class ProjectExportService {
  ProjectExportService._();

  static Future<File> createReport(ProjectData project) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => <pw.Widget>[
          if (project.coverImagePath != null &&
              File(project.coverImagePath!).existsSync()) ...<pw.Widget>[
            pw.Container(
              height: 220,
              width: double.infinity,
              alignment: pw.Alignment.center,
              child: pw.Image(
                pw.MemoryImage(File(project.coverImagePath!).readAsBytesSync()),
                // Keep the complete cover visible for portrait and landscape
                // images. `cover` cropped the top and bottom of the photo.
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Text(project.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(project.location),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Field', 'Value'],
            data: <List<String>>[
              <String>['Project code', project.code],
              <String>['Client / Company', project.client],
              <String>['Photos', '${project.photoCount}'],
              <String>['Locations', '${project.locationCount}'],
              <String>['Storage', project.storageLabel],
              <String>['Status', project.status.name],
            ],
          ),
          if (project.description.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text('Description',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(project.description),
          ],
          if (project.photos.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text('Photo records',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...project.photos.map(
              (photo) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(
                  '${photo.capturedAt.toLocal()}  ${photo.location}',
                ),
              ),
            ),
          ],
        ],
      ),
    );

    for (var index = 0; index < project.photos.length; index++) {
      final photo = project.photos[index];
      final imageFile = File(photo.path);
      if (!await imageFile.exists()) continue;
      final image = pw.MemoryImage(await imageFile.readAsBytes());
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => pw.Column(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final safeName = project.name
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final timestamp = _formatTimestamp(DateTime.now());
    final projectPart = safeName.isEmpty ? 'Project' : safeName;
    final file = File(
      '${directory.path}/GPSMark_${projectPart}_$timestamp.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
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
}
