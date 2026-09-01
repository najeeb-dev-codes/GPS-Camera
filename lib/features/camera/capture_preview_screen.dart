import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../settings/photo_quality/models/photo_quality_settings.dart';
import '../settings/photo_quality/services/photo_quality_processing_service.dart';
import '../gallery/gallery_screen.dart';
import '../projects/project_details_screen.dart';
import '../stamp_templates/stamp_templates_screen.dart';
import 'save_photo_to_screen.dart';
import 'widgets/image_responsive_stamp.dart';
import 'widgets/stamp_layout_metrics.dart';

class CapturePreviewScreen extends StatefulWidget {
  const CapturePreviewScreen({
    super.key,
    required this.imagePath,
    required this.originalCameraPath,
    required this.templateIndex,
    required this.stampData,
    required this.capturedAt,
    required this.photoAspectRatio,
    required this.photoQualitySettings,
    this.initialProjectId,
  });

  /// Normalized upright PNG used only for review/compositing.
  final String imagePath;

  /// Untouched camera JPEG used only as the source of safe EXIF fields.
  final String originalCameraPath;
  final int templateIndex;
  /// Frozen live GPS stamp captured at shutter time.
  final GpsStampData stampData;
  final DateTime capturedAt;

  /// Final camera frame ratio at shutter time.
  final double photoAspectRatio;

  /// Frozen Photo Quality settings used for this specific capture.
  final PhotoQualitySettings photoQualitySettings;
  final String? initialProjectId;

  @override
  State<CapturePreviewScreen> createState() =>
      _CapturePreviewScreenState();
}

class _CapturePreviewScreenState
    extends State<CapturePreviewScreen> {
  late int _selectedTemplateIndex;

  bool _isSaving = false;
  bool _showSignatureLabel = false;
  bool _showLocationVerified = false;
  Timer? _locationVerifiedDelayTimer;
  Timer? _locationVerifiedHideTimer;

  /// Used to capture only:
  ///
  /// Camera photo
  /// +
  /// GPS stamp overlay
  /// +
  /// Optional blank white signature label
  ///
  /// into one final image.
  final GlobalKey _previewKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();

    _selectedTemplateIndex =
        widget.templateIndex;

    _locationVerifiedDelayTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() => _showLocationVerified = true);

        _locationVerifiedHideTimer = Timer(
          const Duration(seconds: 5),
          () {
            if (mounted) {
              setState(() => _showLocationVerified = false);
            }
          },
        );
      },
    );
  }

  // ===========================================================================
  // FROZEN STAMP DATA
  // ===========================================================================

  GpsStampData get _stampData => widget.stampData;

  // ===========================================================================
  // RETAKE
  // ===========================================================================

  Future<void> _retake() async {
    if (_isSaving) return;

    await _deleteTemporaryFiles();

    if (!mounted) return;

    Navigator.of(context).pop(
      _selectedTemplateIndex,
    );
  }

  Future<void> _deleteTemporaryFiles() async {
    for (final path in <String>{
      widget.imagePath,
      widget.originalCameraPath,
    }) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (error) {
        debugPrint('Temporary capture cleanup error: $error');
      }
    }
  }

  // ===========================================================================
  // EDIT STAMP
  // ===========================================================================

  Future<void> _editStamp() async {
    if (_isSaving) return;

    final selected =
        await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) =>
            StampTemplatesScreen(
          selectionMode: true,
          initialSelectedIndex:
              _selectedTemplateIndex,
          stampData: widget.stampData,
        ),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedTemplateIndex =
          selected;
    });
  }

  // ===========================================================================
  // CREATE STAMPED IMAGE
  // ===========================================================================

  Future<Uint8List>
      _captureStampedImage() async {
    // Ensure the coordinate map is decoded before RepaintBoundary captures
    // the stamp. Without this, a very fast save can burn the loading fallback
    // into the final photo instead of the map.
    await _prepareStampAssets();

    // Wait until Flutter completely paints
    // the current photo + stamp.
    await WidgetsBinding.instance.endOfFrame;

    final context =
        _previewKey.currentContext;

    if (context == null) {
      throw Exception(
        'Photo preview is not available.',
      );
    }

    final renderObject =
        context.findRenderObject();

    if (renderObject
        is! RenderRepaintBoundary) {
      throw Exception(
        'Unable to render stamped photo.',
      );
    }

    // -------------------------------------------------------------------------
    // Convert visible preview into an image.
    // -------------------------------------------------------------------------

    final logicalSize = renderObject.size;
    final targetLongEdge =
        widget.photoQualitySettings.resolution.targetLongEdge.toDouble();
    final logicalLongEdge = logicalSize.width > logicalSize.height
        ? logicalSize.width
        : logicalSize.height;
    final pixelRatio =
        (targetLongEdge / logicalLongEdge).clamp(1.0, 8.0).toDouble();

    final ui.Image image = await renderObject.toImage(
      pixelRatio: pixelRatio,
    );

    try {
      final ByteData? byteData =
          await image.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception(
          'Unable to generate stamped image.',
        );
      }

      return byteData.buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _prepareStampAssets() async {
    try {
      await precacheImage(
        const AssetImage('assets/icon/app_icon.png'),
        context,
      );
    } catch (error) {
      debugPrint('Stamp app icon preload skipped: $error');
    }
  }

  // ===========================================================================
  // SAVE PHOTO
  // ===========================================================================

  Future<void> _savePhoto() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    File? processedTemporaryFile;

    try {
      final temporaryPhoto = File(widget.imagePath);
      final originalCameraPhoto = File(widget.originalCameraPath);

      if (!await temporaryPhoto.exists()) {
        throw Exception('Captured photo was not found.');
      }

      // 1. Render the exact visible crop + GPS stamp at a resolution that
      // follows the selected Photo Quality resolution.
      final stampedBytes = await _captureStampedImage();
      if (stampedBytes.isEmpty) {
        throw Exception('Stamped photo data is empty.');
      }

      // 2. Apply the frozen Photo Quality settings for this capture.
      final processed = await PhotoQualityProcessingService.process(
        stampedPngBytes: stampedBytes,
        originalCameraPath: originalCameraPhoto.path,
        stampData: widget.stampData,
        capturedAt: widget.capturedAt,
        settings: widget.photoQualitySettings,
      );

      processedTemporaryFile = File(processed.path);

      // 3. Let the user choose Device Gallery or a persistent Project Folder.
      // The generated image is already stamped and quality-processed, so the
      // destination screen only decides where the exact same file is stored.
      final destinationResult = await Navigator.of(context).push<SavePhotoResult>(
        MaterialPageRoute(
          builder: (_) => SavePhotoToScreen(
            processedImagePath: processed.path,
            location: widget.stampData.title ?? widget.stampData.address,
            capturedAt: widget.capturedAt,
            stampData: widget.stampData,
            captureMetadata: processed.metadata,
            initialProjectId: widget.initialProjectId,
          ),
        ),
      );

      if (destinationResult == null || !mounted) return;

      await _deleteTemporaryFiles();
      if (!mounted) return;

      final destination = destinationResult.projectId == null
          ? const GalleryScreen()
          : ProjectDetailsScreen(projectId: destinationResult.projectId!);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (error) {
      debugPrint('Save photo error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save photo: $error'),
        ),
      );
    } finally {
      try {
        final file = processedTemporaryFile;
        if (file != null && await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (!didPop) {
          await _retake();
        }
      },
      child: Scaffold(
        backgroundColor:
            AppColors.background,
        appBar: AppBar(
          backgroundColor:
              AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed:
                _isSaving
                    ? null
                    : _retake,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          title: Text(
            'Preview',
            style:
                AppTypography
                    .h3
                    .copyWith(
              color:
                  AppColors.textPrimary,
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final isTablet =
                  constraints.maxWidth >=
                      600;

              final horizontalPadding =
                  isTablet
                      ? 40.0
                      : AppSpacing
                          .screenPadding;

              return Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxWidth:
                        isTablet
                            ? 600
                            : double
                                .infinity,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      18,
                    ),
                    child: Column(
                      children: [
                        _buildSignatureToggle(),

                        _buildLocationVerifiedMessage(),

                        const SizedBox(
                          height: 8,
                        ),

                        // =====================================================
                        // PHOTO PREVIEW
                        // =====================================================

                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: widget.photoAspectRatio > 0
                                  ? widget.photoAspectRatio
                                  : 4 / 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  RepaintBoundary(
                                    key: _previewKey,
                                    child: LayoutBuilder(
                                      builder: (context, photoConstraints) {
                                        final photoWidth =
                                            photoConstraints.maxWidth;
                                        final photoHeight =
                                            photoConstraints.maxHeight;
                                        final labelHeight = _showSignatureLabel
                                            ? StampLayoutMetrics.labelHeight(
                                                photoHeight,
                                              )
                                            : 0.0;
                                        final labelBottomGap =
                                            (photoHeight * 0.025)
                                                .clamp(4.0, 12.0)
                                                .toDouble();
                                        final stampLabelGap =
                                            (photoHeight * 0.018)
                                                .clamp(5.0, 14.0)
                                                .toDouble();

                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.file(
                                              File(widget.imagePath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  color: const Color(
                                                    0xFFE5E7EB,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 56,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                );
                                              },
                                            ),
                                            IgnorePointer(
                                              child: ImageResponsiveStamp(
                                                data: _stampData,
                                                templateIndex:
                                                    _selectedTemplateIndex,
                                                imageSize: Size(
                                                  photoWidth,
                                                  photoHeight,
                                                ),
                                                bottomInset:
                                                    _showSignatureLabel
                                                        ? labelHeight +
                                                            stampLabelGap
                                                        : 0,
                                              ),
                                            ),
                                            if (_showSignatureLabel)
                                              Positioned(
                                                left: StampLayoutMetrics
                                                    .horizontalInset(
                                                  photoWidth,
                                                ),
                                                right: StampLayoutMetrics
                                                    .horizontalInset(
                                                  photoWidth,
                                                ),
                                                bottom: labelBottomGap,
                                                height: labelHeight,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.white,
                                                    border: Border.all(
                                                      color: AppColors.border,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  if (_isSaving)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.30,
                                        ),
                                        alignment: Alignment.center,
                                        child:
                                            const CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // =====================================================
                        // ACTION BUTTONS
                        // =====================================================

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _PreviewActionButton(
                                icon:
                                    Icons
                                        .refresh_rounded,
                                label:
                                    'Retake',
                                onTap:
                                    _isSaving
                                        ? null
                                        : _retake,
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _PreviewActionButton(
                                icon:
                                    Icons
                                        .edit_outlined,
                                label:
                                    'Edit Stamp',
                                onTap:
                                    _isSaving
                                        ? null
                                        : _editStamp,
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _PreviewActionButton(
                                icon:
                                    Icons
                                        .check_rounded,
                                label:
                                    'Save Photo',
                                primary:
                                    true,
                                loading:
                                    _isSaving,
                                onTap:
                                    _isSaving
                                        ? null
                                        : _savePhoto,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SIGNATURE PANEL + TEMPORARY LOCATION MESSAGE
  // ===========================================================================

  Widget _buildSignatureToggle() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving
              ? null
              : () => setState(
                    () => _showSignatureLabel = !_showSignatureLabel,
                  ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signature panel',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 52,
                  height: 32,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch.adaptive(
                      value: _showSignatureLabel,
                      activeColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.45),
                      onChanged: _isSaving
                          ? null
                          : (enabled) {
                              setState(() {
                                _showSignatureLabel = enabled;
                              });
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationVerifiedMessage() {
    return SizedBox(
      height: 42,
      child: AnimatedOpacity(
        opacity: _showLocationVerified ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 19,
              color: Color(0xFF169447),
            ),
            SizedBox(width: 5),
            Text(
              'Location verified',
              style: TextStyle(
                color: Color(0xFF169447),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationVerifiedDelayTimer?.cancel();
    _locationVerifiedHideTimer?.cancel();
    super.dispose();
  }

}

// =============================================================================
// PREVIEW ACTION BUTTON
// =============================================================================

class _PreviewActionButton
    extends StatelessWidget {
  const _PreviewActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        primary
            ? Colors.white
            : AppColors.textPrimary;

    return Material(
      color:
          primary
              ? AppColors.primary
              : AppColors.white,
      borderRadius:
          BorderRadius.circular(
        AppRadius.md,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),
        child: Container(
          height: 64,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius
                    .circular(
              AppRadius.md,
            ),
            border:
                primary
                    ? null
                    : Border.all(
                        color:
                            AppColors
                                .border,
                      ),
          ),
          child:
              loading
                  ? const Center(
                      child:
                          SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          icon,
                          size: 21,
                          color:
                              foregroundColor,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        FittedBox(
                          fit:
                              BoxFit
                                  .scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style:
                                AppTypography
                                    .caption
                                    .copyWith(
                              color:
                                  foregroundColor,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
