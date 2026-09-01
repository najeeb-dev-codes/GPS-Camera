import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/photo_quality/models/photo_capture_metadata.dart';
import '../../shared/widgets/widgets.dart';

class CapturedPhoto {
  const CapturedPhoto({
    required this.id,
    required this.path,
    required this.location,
    required this.capturedAt,
    this.stampData,
    this.captureMetadata,
    this.projectId,
    this.isFavorite = false,
  });

  final String id;
  final String path;
  final String location;
  final DateTime capturedAt;
  final GpsStampData? stampData;
  final PhotoCaptureMetadata? captureMetadata;
  final String? projectId;
  final bool isFavorite;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'location': location,
      'capturedAt': capturedAt.toIso8601String(),
      'stampData': stampData?.toJson(),
      'captureMetadata': captureMetadata?.toJson(),
      'projectId': projectId,
      'isFavorite': isFavorite,
    };
  }

  factory CapturedPhoto.fromJson(
    Map<String, dynamic> json,
  ) {
    return CapturedPhoto(
      id: json['id'] as String,
      path: json['path'] as String,
      location: json['location'] as String,
      capturedAt: DateTime.parse(
        json['capturedAt'] as String,
      ),
      stampData: json['stampData'] is Map
          ? GpsStampData.fromJson(
              Map<String, dynamic>.from(json['stampData'] as Map),
            )
          : null,
      captureMetadata: json['captureMetadata'] is Map
          ? PhotoCaptureMetadata.fromJson(
              Map<String, dynamic>.from(json['captureMetadata'] as Map),
            )
          : null,
      projectId: json['projectId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  CapturedPhoto copyWith({
    String? projectId,
    bool? isFavorite,
  }) {
    return CapturedPhoto(
      id: id,
      path: path,
      location: location,
      capturedAt: capturedAt,
      stampData: stampData,
      captureMetadata: captureMetadata,
      projectId: projectId ?? this.projectId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CapturedPhotoService {
  CapturedPhotoService._();

  static const String _storageKey = 'gps_camera_captured_photos_v1';

  static Future<void> saveStampedToDeviceGallery({
    required Uint8List pngBytes,
    required String fileName,
  }) async {
    bool hasAccess = await Gal.hasAccess();

    if (!hasAccess) {
      hasAccess = await Gal.requestAccess();
    }

    if (!hasAccess) {
      throw Exception(
        'Gallery permission was not granted.',
      );
    }

    await Gal.putImageBytes(
      pngBytes,
      name: fileName,
    );
  }

  // ===========================================================================
  // SAVE NORMAL CAMERA PHOTO TO APP GALLERY
  // ===========================================================================

  static Future<CapturedPhoto> saveCapturedPhoto({
    required String sourcePath,
    required String location,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception(
        'Camera photo does not exist: $sourcePath',
      );
    }

    final applicationDirectory = await getApplicationDocumentsDirectory();

    final capturesDirectory = Directory(
      '${applicationDirectory.path}/GPSCamera',
    );

    if (!await capturesDirectory.exists()) {
      await capturesDirectory.create(
        recursive: true,
      );
    }

    final capturedAt = DateTime.now();

    final id = capturedAt.microsecondsSinceEpoch.toString();

    final destinationPath = '${capturesDirectory.path}/GPSCamera_$id.jpg';

    final destinationFile = File(
      destinationPath,
    );

    // -------------------------------------------------------------------------
    // Copy temporary camera image into permanent app storage
    // -------------------------------------------------------------------------

    await sourceFile.copy(
      destinationFile.path,
    );

    if (!await destinationFile.exists()) {
      throw Exception(
        'Unable to create saved photo.',
      );
    }

    final savedPhoto = CapturedPhoto(
      id: id,
      path: destinationFile.path,
      location: location,
      capturedAt: capturedAt,
    );

    final oldPhotos = await loadPhotos();

    final newPhotos = <CapturedPhoto>[
      savedPhoto,
      ...oldPhotos,
    ];

    await _write(
      newPhotos,
    );

    return savedPhoto;
  }

  // ===========================================================================
  // SAVE PHOTO TO DEVICE GALLERY
  // ===========================================================================

  static Future<void> saveToDeviceGallery({
    required String imagePath,
  }) async {
    final file = File(
      imagePath,
    );

    if (!await file.exists()) {
      throw Exception(
        'Photo does not exist for device gallery save.',
      );
    }

    try {
      // -----------------------------------------------------------------------
      // Check permission/access
      // -----------------------------------------------------------------------

      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (!hasAccess) {
        throw Exception(
          'Gallery permission was not granted.',
        );
      }

      // -----------------------------------------------------------------------
      // Save image into phone Gallery / Google Photos
      // -----------------------------------------------------------------------

      await Gal.putImage(
        file.path,
      );

      print(
        'Photo saved to device gallery: ${file.path}',
      );
    } catch (e) {
      print(
        'Device gallery save error: $e',
      );

      rethrow;
    }
  }

  // ===========================================================================
  // SAVE GENERATED PNG
  // ===========================================================================

  static Future<CapturedPhoto> saveStampedPhoto({
    required Uint8List pngBytes,
    required String location,
    required DateTime capturedAt,
    required GpsStampData stampData,
  }) async {
    final applicationDirectory = await getApplicationDocumentsDirectory();

    final capturesDirectory = Directory(
      '${applicationDirectory.path}/GPSCamera',
    );

    if (!await capturesDirectory.exists()) {
      await capturesDirectory.create(
        recursive: true,
      );
    }

    final id = capturedAt.microsecondsSinceEpoch.toString();

    final file = File(
      '${capturesDirectory.path}/GPSCamera_$id.png',
    );

    await file.writeAsBytes(
      pngBytes,
      flush: true,
    );

    final photo = CapturedPhoto(
      id: id,
      path: file.path,
      location: location,
      capturedAt: capturedAt,
      stampData: stampData,
    );

    final existingPhotos = await loadPhotos();

    await _write(
      <CapturedPhoto>[
        photo,
        ...existingPhotos,
      ],
    );

    return photo;
  }

  // ===========================================================================
  // SAVE PHOTO PROCESSED BY PHOTO QUALITY MODULE
  // ===========================================================================

  static Future<CapturedPhoto> saveProcessedPhoto({
    required String sourcePath,
    required String location,
    required DateTime capturedAt,
    required GpsStampData stampData,
    required PhotoCaptureMetadata captureMetadata,
    String? projectId,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Processed photo does not exist: $sourcePath');
    }

    final applicationDirectory = await getApplicationDocumentsDirectory();
    final capturesDirectory = Directory(
      '${applicationDirectory.path}/GPSCamera',
    );

    if (!await capturesDirectory.exists()) {
      await capturesDirectory.create(recursive: true);
    }

    final id = capturedAt.microsecondsSinceEpoch.toString();
    final extension = sourcePath.split('.').last.toLowerCase();
    final destinationFile = File(
      '${capturesDirectory.path}/GPSCamera_$id.$extension',
    );

    await sourceFile.copy(destinationFile.path);

    if (!await destinationFile.exists()) {
      throw Exception('Unable to create processed photo.');
    }

    final actualMetadata = PhotoCaptureMetadata(
      width: captureMetadata.width,
      height: captureMetadata.height,
      fileSizeBytes: await destinationFile.length(),
      format: captureMetadata.format,
      jpegQuality: captureMetadata.jpegQuality,
      resolution: captureMetadata.resolution,
      hdrApplied: captureMetadata.hdrApplied,
      autoEnhanceApplied: captureMetadata.autoEnhanceApplied,
      exifPreserved: captureMetadata.exifPreserved,
      gpsEmbedded: captureMetadata.gpsEmbedded,
    );

    final photo = CapturedPhoto(
      id: id,
      path: destinationFile.path,
      location: location,
      capturedAt: capturedAt,
      stampData: stampData,
      captureMetadata: actualMetadata,
      projectId: projectId,
    );

    final existingPhotos = await loadPhotos();
    // Saving can be retried when device-gallery export fails. Replace the
    // same capture record instead of creating duplicate gallery entries.
    await _write(<CapturedPhoto>[
      photo,
      ...existingPhotos.where((existing) => existing.id != photo.id),
    ]);

    return photo;
  }

  // ===========================================================================
  // LOAD PHOTOS
  // ===========================================================================

  static Future<List<CapturedPhoto>> loadPhotos() async {
    final preferences = await SharedPreferences.getInstance();

    final savedValue = preferences.getString(
      _storageKey,
    );

    if (savedValue == null || savedValue.isEmpty) {
      return <CapturedPhoto>[];
    }

    try {
      final decoded = jsonDecode(savedValue) as List<dynamic>;

      final List<CapturedPhoto> photos = [];

      for (final item in decoded) {
        try {
          final photo = CapturedPhoto.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          );

          final file = File(photo.path);

          if (file.existsSync()) {
            photos.add(photo);
          }
        } catch (_) {
          // Ignore invalid gallery entry.
        }
      }

      return photos;
    } catch (_) {
      return <CapturedPhoto>[];
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  static Future<void> deletePhotos(
    Iterable<String> ids,
  ) async {
    final idsToDelete = ids.toSet();

    final photos = await loadPhotos();

    for (final photo in photos) {
      if (!idsToDelete.contains(
        photo.id,
      )) {
        continue;
      }

      final file = File(photo.path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    final remainingPhotos = photos
        .where(
          (photo) => !idsToDelete.contains(
            photo.id,
          ),
        )
        .toList();

    await _write(
      remainingPhotos,
    );
  }

  // ===========================================================================
  // FAVORITES / PROJECT ASSIGNMENT
  // ===========================================================================

  static Future<void> setFavorite(
    Iterable<String> ids, {
    required bool favorite,
  }) async {
    final selected = ids.toSet();
    final photos = await loadPhotos();
    await _write(
      photos
          .map(
            (photo) => selected.contains(photo.id)
                ? photo.copyWith(isFavorite: favorite)
                : photo,
          )
          .toList(),
    );
  }

  static Future<List<CapturedPhoto>> moveToProject(
    Iterable<String> ids, {
    required String projectId,
  }) async {
    final selected = ids.toSet();
    final photos = await loadPhotos();
    final moved = <CapturedPhoto>[];
    final updated = photos.map((photo) {
      if (!selected.contains(photo.id)) return photo;
      final value = photo.copyWith(projectId: projectId);
      moved.add(value);
      return value;
    }).toList();
    await _write(updated);
    return moved;
  }

  // ===========================================================================
  // WRITE
  // ===========================================================================

  static Future<void> _write(
    List<CapturedPhoto> photos,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      photos
          .map(
            (photo) => photo.toJson(),
          )
          .toList(),
    );

    final success = await preferences.setString(
      _storageKey,
      encoded,
    );

    if (!success) {
      throw Exception(
        'Unable to save gallery information.',
      );
    }
  }
}
