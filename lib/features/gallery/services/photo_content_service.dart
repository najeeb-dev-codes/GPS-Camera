import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/services/captured_photo_service.dart';

class ResolvedPhotoContent {
  const ResolvedPhotoContent({
    required this.file,
    required this.fileName,
    required this.mimeType,
    required this.isTemporary,
  });

  final File file;
  final String fileName;
  final String mimeType;
  final bool isTemporary;
}

class PhotoContentService {
  PhotoContentService._();

  static Future<ResolvedPhotoContent> resolve({
    required CapturedPhoto? photo,
    required String? imageAsset,
  }) async {
    if (photo != null) {
      final file = File(photo.path);
      if (!await file.exists()) {
        throw Exception('The saved photo file was not found.');
      }

      final extension = _extensionOf(file.path);
      return ResolvedPhotoContent(
        file: file,
        fileName: '${AppBrand.photoFilePrefix}_${photo.id}.$extension',
        mimeType: _mimeType(extension),
        isTemporary: false,
      );
    }

    final assetPath = imageAsset?.trim();
    if (assetPath == null || assetPath.isEmpty) {
      throw Exception('No photo is available.');
    }

    final data = await rootBundle.load(assetPath);
    final extension = _extensionOf(assetPath);
    final temporaryDirectory = await getTemporaryDirectory();
    final file = File(
      '${temporaryDirectory.path}/${AppBrand.photoFilePrefix}_sample_'
      '${DateTime.now().microsecondsSinceEpoch}.$extension',
    );

    await file.writeAsBytes(
      data.buffer.asUint8List(),
      flush: true,
    );

    return ResolvedPhotoContent(
      file: file,
      fileName: file.uri.pathSegments.last,
      mimeType: _mimeType(extension),
      isTemporary: true,
    );
  }

  static String _extensionOf(String path) {
    final fileName = path.split('/').last.split('\\').last;
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'jpg';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String _mimeType(String extension) => switch (extension) {
        'png' => 'image/png',
        'heic' || 'heif' => 'image/heic',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
