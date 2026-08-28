import 'photo_capture_metadata.dart';

class PhotoProcessingResult {
  const PhotoProcessingResult({
    required this.path,
    required this.metadata,
  });

  final String path;
  final PhotoCaptureMetadata metadata;
}
