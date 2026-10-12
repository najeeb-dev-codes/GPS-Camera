import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_brand.dart';
import 'app_settings_service.dart';

class FileNamingService {
  FileNamingService._();

  static const String _nextSequenceKey = 'file_naming_next_sequence_v1';

  static String projectPrefix(String projectName) {
    final cleaned = projectName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (cleaned.isEmpty) return 'PRJ';
    final end = cleaned.length < 3 ? cleaned.length : 3;
    return cleaned.substring(0, end);
  }

  static Future<void> resetSequence(int startNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_nextSequenceKey, startNumber < 0 ? 0 : startNumber);
  }

  static Future<String> createFileName({
    required String extension,
    String? projectName,
    double? latitude,
    DateTime? capturedAt,
  }) async {
    final settings = AppSettingsService.instance;
    await settings.ensureFileNamingSettingsLoaded();
    final applicationDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${applicationDirectory.path}/${AppBrand.internalPhotoDirectory}',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    final now = capturedAt ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final sequence =
        prefs.getInt(_nextSequenceKey) ?? settings.sequenceStartNumber;
    final parts = _parts(
      settings: settings,
      time: now,
      sequence: sequence,
      projectName: projectName,
      latitude: latitude,
    );
    var base = parts.map(_safePart).where((part) => part.isNotEmpty).join('_');
    if (base.isEmpty) base = sequence.toString().padLeft(3, '0');
    final safeExtension = extension.replaceFirst('.', '').toLowerCase();
    var fileName = '$base.$safeExtension';

    if (settings.avoidDuplicateNames) {
      var duplicate = 1;
      while (await File('${directory.path}/$fileName').exists()) {
        fileName = '${base}_$duplicate.$safeExtension';
        duplicate++;
      }
    }

    if (settings.sequenceNumberEnabled &&
        settings.namingPatternChips.contains('Sequence')) {
      await prefs.setInt(_nextSequenceKey, sequence + 1);
    }
    return fileName;
  }

  static String preview({String? projectName}) {
    final settings = AppSettingsService.instance;
    final parts = _parts(
      settings: settings,
      time: DateTime.now(),
      sequence: settings.sequenceStartNumber,
      projectName: projectName,
      latitude: 8.713900,
    );
    return '${parts.map(_safePart).where((part) => part.isNotEmpty).join('_')}.jpg';
  }

  static List<String> _parts({
    required AppSettingsService settings,
    required DateTime time,
    required int sequence,
    required String? projectName,
    required double? latitude,
  }) {
    final parts = <String>[];
    final hasProject = projectName != null && projectName.trim().isNotEmpty;
    if (hasProject) parts.add(projectPrefix(projectName!));

    for (final chip in settings.namingPatternChips) {
      switch (chip) {
        case 'Project':
          if (!hasProject) parts.add(settings.fileNamingPrefix);
        case 'Date':
          parts.add(_date(time, settings.dateFormat));
        case 'Time':
          parts.add(_time(time, settings.timeFormat));
        case 'Sequence':
          if (settings.sequenceNumberEnabled) {
            parts.add(sequence.toString().padLeft(3, '0'));
          }
        case 'Latitude':
          if (latitude != null) parts.add(latitude.toStringAsFixed(6));
      }
    }
    if (parts.isEmpty) parts.add(sequence.toString().padLeft(3, '0'));
    return parts;
  }

  static String _safePart(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9.-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');

  static String _date(DateTime value, String format) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return switch (format) {
      'DDMMYYYY' => '$day$month$year',
      'MM-DD-YYYY' => '$month-$day-$year',
      _ => '$year$month$day',
    };
  }

  static String _time(DateTime value, String format) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return format == 'HH-mm-ss'
        ? '$hour-$minute-$second'
        : '$hour$minute$second';
  }
}
