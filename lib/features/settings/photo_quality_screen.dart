import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'photo_quality/models/photo_quality_settings.dart';
import 'photo_quality/services/photo_quality_capability_service.dart';
import 'photo_quality/services/photo_quality_settings_service.dart';

class PhotoQualityScreen extends StatefulWidget {
  const PhotoQualityScreen({super.key});

  @override
  State<PhotoQualityScreen> createState() => _PhotoQualityScreenState();
}

class _PhotoQualityScreenState extends State<PhotoQualityScreen> {
  final _service = PhotoQualitySettingsService.instance;
  PhotoQualityCapabilities? _capabilities;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.ensureLoaded();
    final capabilities = await PhotoQualityCapabilityService.read();
    if (!mounted) return;

    if (!capabilities.heicSupported &&
        _service.current.format == PhotoImageFormatOption.heic) {
      _service.setFormat(PhotoImageFormatOption.jpeg);
    }

    setState(() => _capabilities = capabilities);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Photo Quality'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) {
            final settings = _service.current;
            final formats = PhotoImageFormatOption.values
                .where(
                  (value) => value != PhotoImageFormatOption.heic ||
                      (_capabilities?.heicSupported ?? false),
                )
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 600
                    ? 48.0
                    : AppSpacing.screenPadding;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          24,
                        ),
                        children: [
                          DropdownSettingRow<PhotoResolutionOption>(
                            title: 'Photo Resolution',
                            value: settings.resolution,
                            items: PhotoResolutionOption.values,
                            itemLabel: (value) => value.label,
                            onChanged: (value) {
                              if (value != null) _service.setResolution(value);
                            },
                          ),
                          DropdownSettingRow<PhotoImageFormatOption>(
                            title: 'Image Format',
                            value: formats.contains(settings.format)
                                ? settings.format
                                : PhotoImageFormatOption.jpeg,
                            items: formats,
                            itemLabel: (value) => value.label,
                            onChanged: (value) {
                              if (value != null) _service.setFormat(value);
                            },
                          ),
                          if (_capabilities != null &&
                              !_capabilities!.heicSupported)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'HEIC is hidden because this device does not support safe HEIC encoding.',
                                style: AppTypography.caption,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSlider(
                            label: 'JPEG Quality',
                            value: settings.jpegQuality.toDouble(),
                            min: 1,
                            max: 100,
                            valueLabelBuilder: (value) => '${value.round()}%',
                            onChanged: _service.setJpegQuality,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          ToggleSettingRow(
                            title: 'HDR Capture',
                            subtitle: 'Applies a safe single-frame HDR tone enhancement to the final photo.',
                            value: settings.hdrCapture,
                            onChanged: _service.setHdrCapture,
                          ),
                          ToggleSettingRow(
                            title: 'Auto Enhance',
                            subtitle: 'Applies light contrast, saturation and brightness correction.',
                            value: settings.autoEnhance,
                            onChanged: _service.setAutoEnhance,
                          ),
                          DropdownSettingRow<WatermarkCompressionOption>(
                            title: 'Watermark Compression',
                            value: settings.watermarkCompression,
                            items: WatermarkCompressionOption.values,
                            itemLabel: (value) => value.label,
                            onChanged: (value) {
                              if (value != null) {
                                _service.setWatermarkCompression(value);
                              }
                            },
                          ),
                          ToggleSettingRow(
                            title: 'Preserve EXIF Metadata',
                            value: settings.preserveExifMetadata,
                            onChanged: _service.setPreserveExifMetadata,
                          ),
                          ToggleSettingRow(
                            title: 'Embed GPS in EXIF',
                            subtitle: 'Uses the frozen GPS coordinates from shutter time.',
                            value: settings.embedGpsInExif,
                            onChanged: _service.setEmbedGpsInExif,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Estimated size',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                                Text(
                                  settings.estimatedSizeLabel,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Actual size changes with scene detail and selected format.',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: AppSizes.iconSm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        16,
                      ),
                      child: AppSecondaryButton(
                        label: 'Restore Defaults',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          _service.reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo quality settings restored'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
