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
              <String>['Stamp template', project.defaultStampTemplate],
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
                  '${photo.capturedAt.toLocal()}  •  ${photo.location}',
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final safeName = project.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final file = File(
      '${directory.path}/${safeName}_Project_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }
}
