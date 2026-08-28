import 'package:flutter/material.dart';

import '../../../core/services/captured_photo_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

class PhotoInformationPanel extends StatelessWidget {
  const PhotoInformationPanel({
    super.key,
    required this.photo,
    required this.stampData,
    required this.capturedLabel,
  });

  final CapturedPhoto? photo;
  final GpsStampData stampData;
  final String capturedLabel;

  @override
  Widget build(BuildContext context) {
    final metadata = photo?.captureMetadata;

    return Column(
      key: const ValueKey<String>('information-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image information',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        CoordinateInfoRow(
          label: 'Coordinates',
          value: stampData.coordinates ?? '—',
        ),
        CoordinateInfoRow(label: 'Captured', value: capturedLabel),
        CoordinateInfoRow(
          label: 'GPS Accuracy',
          value: stampData.accuracy ?? '—',
        ),
        CoordinateInfoRow(
          label: 'Altitude',
          value: stampData.altitude ?? '—',
        ),
        if (metadata != null) ...[
          CoordinateInfoRow(
            label: 'Resolution',
            value: '${metadata.width} × ${metadata.height}',
          ),
          CoordinateInfoRow(label: 'File size', value: metadata.fileSizeLabel),
          CoordinateInfoRow(label: 'Format', value: metadata.format),
          CoordinateInfoRow(
            label: 'Photo quality',
            value: '${metadata.jpegQuality}%',
          ),
          CoordinateInfoRow(
            label: 'HDR',
            value: metadata.hdrApplied ? 'Applied' : 'Off',
          ),
          CoordinateInfoRow(
            label: 'GPS EXIF',
            value: metadata.gpsEmbedded ? 'Embedded' : 'Not embedded',
          ),
        ],
      ],
    );
  }
}
