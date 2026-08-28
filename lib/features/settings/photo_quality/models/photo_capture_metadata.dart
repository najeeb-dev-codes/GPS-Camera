class PhotoCaptureMetadata {
  const PhotoCaptureMetadata({
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.format,
    required this.jpegQuality,
    required this.resolution,
    required this.hdrApplied,
    required this.autoEnhanceApplied,
    required this.exifPreserved,
    required this.gpsEmbedded,
  });

  final int width;
  final int height;
  final int fileSizeBytes;
  final String format;
  final int jpegQuality;
  final String resolution;
  final bool hdrApplied;
  final bool autoEnhanceApplied;
  final bool exifPreserved;
  final bool gpsEmbedded;

  String get fileSizeLabel {
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
    return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  Map<String, Object?> toJson() => {
        'width': width,
        'height': height,
        'fileSizeBytes': fileSizeBytes,
        'format': format,
        'jpegQuality': jpegQuality,
        'resolution': resolution,
        'hdrApplied': hdrApplied,
        'autoEnhanceApplied': autoEnhanceApplied,
        'exifPreserved': exifPreserved,
        'gpsEmbedded': gpsEmbedded,
      };

  factory PhotoCaptureMetadata.fromJson(Map<String, dynamic> json) {
    return PhotoCaptureMetadata(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      format: json['format'] as String? ?? 'JPEG',
      jpegQuality: (json['jpegQuality'] as num?)?.toInt() ?? 95,
      resolution: json['resolution'] as String? ?? 'Unknown',
      hdrApplied: json['hdrApplied'] as bool? ?? false,
      autoEnhanceApplied: json['autoEnhanceApplied'] as bool? ?? false,
      exifPreserved: json['exifPreserved'] as bool? ?? false,
      gpsEmbedded: json['gpsEmbedded'] as bool? ?? false,
    );
  }
}
