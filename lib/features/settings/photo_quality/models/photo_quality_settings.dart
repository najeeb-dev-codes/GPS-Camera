enum PhotoResolutionOption {
  high('High', 3264),
  medium('Medium', 2048),
  low('Low', 1280);

  const PhotoResolutionOption(this.label, this.targetLongEdge);

  final String label;
  final int targetLongEdge;

  static PhotoResolutionOption fromName(String? value) {
    return PhotoResolutionOption.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PhotoResolutionOption.high,
    );
  }
}

enum PhotoImageFormatOption {
  jpeg('JPEG', 'jpg'),
  png('PNG', 'png'),
  heic('HEIC', 'heic');

  const PhotoImageFormatOption(this.label, this.extension);

  final String label;
  final String extension;

  static PhotoImageFormatOption fromName(String? value) {
    return PhotoImageFormatOption.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PhotoImageFormatOption.png,
    );
  }
}

enum WatermarkCompressionOption {
  highQuality('High Quality', 0, 4),
  balanced('Balanced', 8, 6),
  smallSize('Small size', 18, 8);

  const WatermarkCompressionOption(
    this.label,
    this.qualityPenalty,
    this.pngLevel,
  );

  final String label;
  final int qualityPenalty;
  final int pngLevel;

  static WatermarkCompressionOption fromName(String? value) {
    return WatermarkCompressionOption.values.firstWhere(
      (item) => item.name == value,
      orElse: () => WatermarkCompressionOption.balanced,
    );
  }
}

class PhotoQualitySettings {
  static const PhotoResolutionOption defaultResolution =
      PhotoResolutionOption.high;

  const PhotoQualitySettings({
    this.resolution = defaultResolution,
    this.format = PhotoImageFormatOption.png,
    this.jpegQuality = 95,
    this.hdrCapture = false,
    this.autoEnhance = false,
    this.watermarkCompression = WatermarkCompressionOption.balanced,
    this.preserveExifMetadata = false,
    this.embedGpsInExif = true,
  });

  final PhotoResolutionOption resolution;
  final PhotoImageFormatOption format;
  final int jpegQuality;
  final bool hdrCapture;
  final bool autoEnhance;
  final WatermarkCompressionOption watermarkCompression;
  final bool preserveExifMetadata;
  final bool embedGpsInExif;

  int get effectiveJpegQuality =>
      (jpegQuality - watermarkCompression.qualityPenalty).clamp(1, 100).toInt();

  String get estimatedSizeLabel {
    final baseMb = switch (resolution) {
      PhotoResolutionOption.high => 5.0,
      PhotoResolutionOption.medium => 2.7,
      PhotoResolutionOption.low => 1.3,
    };

    final formatFactor = switch (format) {
      PhotoImageFormatOption.jpeg => 1.0,
      PhotoImageFormatOption.png => 2.2,
      PhotoImageFormatOption.heic => 0.58,
    };

    final qualityFactor = format == PhotoImageFormatOption.png
        ? 1.0
        : (0.30 + (effectiveJpegQuality / 100) * 0.70);
    final enhancementFactor = (hdrCapture || autoEnhance) ? 1.05 : 1.0;

    final high = (baseMb * formatFactor * qualityFactor * enhancementFactor)
        .clamp(0.3, 30.0);
    final low = (high * 0.58).clamp(0.2, high);

    return '${low.toStringAsFixed(1)} – ${high.toStringAsFixed(1)} MB';
  }

  PhotoQualitySettings copyWith({
    PhotoResolutionOption? resolution,
    PhotoImageFormatOption? format,
    int? jpegQuality,
    bool? hdrCapture,
    bool? autoEnhance,
    WatermarkCompressionOption? watermarkCompression,
    bool? preserveExifMetadata,
    bool? embedGpsInExif,
  }) {
    return PhotoQualitySettings(
      resolution: resolution ?? this.resolution,
      format: format ?? this.format,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      hdrCapture: hdrCapture ?? this.hdrCapture,
      autoEnhance: autoEnhance ?? this.autoEnhance,
      watermarkCompression: watermarkCompression ?? this.watermarkCompression,
      preserveExifMetadata:
          preserveExifMetadata ?? this.preserveExifMetadata,
      embedGpsInExif: embedGpsInExif ?? this.embedGpsInExif,
    );
  }
}
