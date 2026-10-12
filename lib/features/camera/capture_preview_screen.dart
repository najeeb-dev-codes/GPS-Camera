import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/ad_service.dart';
import '../../shared/widgets/widgets.dart';
import '../settings/photo_quality/models/photo_quality_settings.dart';
import '../settings/photo_quality/models/photo_processing_result.dart';
import '../settings/photo_quality/services/photo_quality_processing_service.dart';
import '../gallery/gallery_screen.dart';
import '../projects/project_details_screen.dart';
import '../stamp_templates/stamp_templates_screen.dart';
import 'save_photo_to_screen.dart';
import 'services/captured_image_orientation_service.dart';
import 'widgets/image_responsive_stamp.dart';
import 'widgets/stamp_layout_metrics.dart';

class CapturePreviewScreen extends StatefulWidget {
  const CapturePreviewScreen({
    super.key,
    required this.originalCameraPath,
    required this.captureOrientation,
    required this.templateIndex,
    required this.stampData,
    required this.capturedAt,
    required this.photoAspectRatio,
    required this.photoQualitySettings,
    this.mirrorHorizontally = false,
    this.initialProjectId,
  });

  /// Untouched camera JPEG used for background preview preparation and as the
  /// source of safe EXIF fields during final export.
  final String originalCameraPath;
  final DeviceOrientation captureOrientation;
  final int templateIndex;
  /// Frozen live GPS stamp captured at shutter time.
  final GpsStampData stampData;
  final DateTime capturedAt;

  /// Final camera frame ratio at shutter time.
  final double photoAspectRatio;

  /// Frozen Photo Quality settings used for this specific capture.
  final PhotoQualitySettings photoQualitySettings;
  final bool mirrorHorizontally;
  final String? initialProjectId;

  @override
  State<CapturePreviewScreen> createState() =>
      _CapturePreviewScreenState();
}

class _CapturePreviewScreenState
    extends State<CapturePreviewScreen> {
  late int _selectedTemplateIndex;

  bool _isSaving = false;
  bool _isPreparingImage = true;
  bool _showSignatureLabel = false;
  bool _showCaptureMessage = false;
  String? _previewImagePath;
  String? _preparationError;
  bool _useFastPreviewDecode = true;
  bool _showingRawPreview = true;
  Future<PhotoProcessingResult>? _preparedPhoto;
  late double _photoAspectRatio;
  Timer? _captureMessageTimer;

  bool get _actionsLocked => _isPreparingImage || _isSaving;

  double get _displayAspectRatio => _photoAspectRatio > 1
      ? _photoAspectRatio.clamp(1.0, 4 / 3).toDouble()
      : _photoAspectRatio;

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
    _photoAspectRatio = widget.photoAspectRatio > 0
        ? widget.photoAspectRatio
        : 4 / 3;
    _previewImagePath = widget.originalCameraPath;
    _showCaptureMessage = true;
    _captureMessageTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCaptureMessage = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePreviewImage();
    });
  }

  Future<void> _preparePreviewImage() async {
    try {
      // The raw photo is already visible while normalization runs in a
      // background isolate. This restores the older correct landscape
      // orientation without showing an image loader after the shutter.
      final normalized = await CapturedImageOrientationService.normalize(
        sourcePath: widget.originalCameraPath,
        deviceOrientation: widget.captureOrientation,
      );
      await precacheImage(
        ResizeImage.resizeIfNeeded(
          1080,
          null,
          FileImage(File(normalized.path)),
        ),
        context,
      );
      if (!mounted) return;

      setState(() {
        _previewImagePath = normalized.path;
        _photoAspectRatio = normalized.aspectRatio;
        _showingRawPreview = false;
        _isPreparingImage = false;
      });

      // Start the expensive final-image pipeline as soon as the preview is
      // ready. Save Photo receives this same in-flight Future later, so the
      // processing can continue while the user chooses a destination.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPhotoProcessing();
      });
    } catch (error) {
      debugPrint('Preview preparation error: $error');
      if (!mounted) return;
      setState(() {
        _isPreparingImage = false;
        _showingRawPreview = true;
      });
    }
  }

  int get _rawPreviewQuarterTurns => switch (widget.captureOrientation) {
        DeviceOrientation.landscapeLeft => 3,
        DeviceOrientation.landscapeRight => 1,
        DeviceOrientation.portraitDown => 2,
        DeviceOrientation.portraitUp => 0,
      };

  // ===========================================================================
  // FROZEN STAMP DATA
  // ===========================================================================

  GpsStampData get _stampData => widget.stampData;

  Future<PhotoProcessingResult> _startPhotoProcessing() {
    final active = _preparedPhoto;
    if (active != null) return active;

    final future = _preparePhotoForSaving(_captureStampedImage());
    _preparedPhoto = future;

    // Keep the Future alive even when processing finishes after navigation.
    // The Save Photo screen attaches to this exact Future instead of starting
    // another expensive decode/encode pass.
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object _, StackTrace __) {},
      ),
    );
    return future;
  }

  // ===========================================================================
  // RETAKE
  // ===========================================================================

  Future<void> _retake() async {
    if (_actionsLocked) return;

    await _deleteTemporaryFiles();

    if (!mounted) return;

    Navigator.of(context).pop(
      _selectedTemplateIndex,
    );
  }

  Future<void> _deleteTemporaryFiles() async {
    for (final path in <String>{
      widget.originalCameraPath,
      if (_previewImagePath != null) _previewImagePath!,
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
    if (_actionsLocked || _previewImagePath == null) return;

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

    // The stamp changed, so the previous processed file no longer represents
    // the preview. Start a new background preparation from the updated stamp.
    _preparedPhoto = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPhotoProcessing();
    });
  }

  // ===========================================================================
  // CREATE STAMPED IMAGE
  // ===========================================================================

  Future<Uint8List>
      _captureStampedImage() async {
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

    // Start the GPU snapshot before navigation. This keeps the currently
    // painted preview available even after the destination route becomes
    // opaque, while navigation itself can proceed without waiting for bytes.
    final imageFuture = renderObject.toImage(
      pixelRatio: pixelRatio,
    );
    final ui.Image image = await imageFuture;

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

  // ===========================================================================
  // SAVE PHOTO
  // ===========================================================================

  Future<void> _savePhoto() async {
    if (_actionsLocked || _previewImagePath == null) return;

    setState(() {
      _isSaving = true;
    });

    final preparedPhoto = _preparedPhoto ?? _startPhotoProcessing();
    final interstitial = AdService.instance.showInterstitialIfReady();
    PhotoProcessingResult? processed;
    bool cleanupProcessedPhoto = false;

    try {
      // The photo snapshot and final processing are already running while the
      // full-screen ad is visible. If no ad is ready this completes instantly.
      await interstitial;
      if (!mounted) return;

      // The destination receives the same in-flight processing future, so in
      // the usual case its preparation has completed while the ad was open.
      final destinationResult = await Navigator.of(context).push<SavePhotoResult>(
        MaterialPageRoute(
          builder: (_) => SavePhotoToScreen(
            preparedPhoto: preparedPhoto,
            previewImagePath: _previewImagePath!,
            originalImagePath: widget.originalCameraPath,
            location: widget.stampData.title ?? widget.stampData.address,
            capturedAt: widget.capturedAt,
            stampData: widget.stampData,
            initialProjectId: widget.initialProjectId,
          ),
        ),
      );

      // Returning from Save Photo without saving must keep the processed
      // cache file alive. The same in-flight Future is intentionally reused
      // when the user opens Save Photo again.
      if (destinationResult == null || !mounted) return;

      // SavePhotoToScreen only returns a result after the processed image has
      // actually been saved. From this point it is safe to remove the cached
      // processed file during final cleanup.
      cleanupProcessedPhoto = true;
      processed = await preparedPhoto;

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

      AppTopToast.show(
        context,
        message: 'Unable to save photo: $error',
        icon: Icons.error_outline_rounded,
      );
    } finally {
      try {
        final path = cleanupProcessedPhoto ? processed?.path : null;
        if (path != null) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<PhotoProcessingResult> _preparePhotoForSaving(
    Future<Uint8List> stampedImage,
  ) async {
    final stampedBytes = await stampedImage;
    if (stampedBytes.isEmpty) {
      throw Exception('Stamped photo data is empty.');
    }

    return PhotoQualityProcessingService.process(
      stampedPngBytes: stampedBytes,
      originalCameraPath: widget.originalCameraPath,
      stampData: widget.stampData,
      capturedAt: widget.capturedAt,
      settings: widget.photoQualitySettings,
    );
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
            Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed:
                _actionsLocked
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
                  child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            0,
                          ),
                          child: _buildSignatureToggle(),
                        ),

                        const SizedBox(height: 6),

                        // =====================================================
                        // PHOTO PREVIEW
                        // =====================================================

                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Center(
                            child: AspectRatio(
                              aspectRatio: _displayAspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_previewImagePath == null &&
                                      _preparationError != null)
                                    Container(
                                      color: AppColors.inactiveSurface,
                                      padding: const EdgeInsets.all(24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _preparationError!,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodyMedium,
                                      ),
                                    )
                                  else
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
                                            Transform.flip(
                                              flipX: widget.mirrorHorizontally,
                                              child: RotatedBox(
                                                quarterTurns: _showingRawPreview
                                                    ? _rawPreviewQuarterTurns
                                                    : 0,
                                                child: Image(
                                                  image: _useFastPreviewDecode
                                                    ? ResizeImage.resizeIfNeeded(
                                                        1080,
                                                        null,
                                                        FileImage(
                                                          File(
                                                            _previewImagePath!,
                                                          ),
                                                        ),
                                                      )
                                                    : FileImage(
                                                        File(
                                                          _previewImagePath!,
                                                        ),
                                                      ),
                                                  fit: BoxFit.cover,
                                                  gaplessPlayback: true,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      color: const Color(
                                                        0xFFE5E7EB,
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        size: 56,
                                                        color:
                                                            Color(0xFF94A3B8),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
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
                                  if (_showCaptureMessage && !_isSaving)
                                    Center(
                                      child: IgnorePointer(
                                        child: AnimatedOpacity(
                                          opacity:
                                              _showCaptureMessage ? 1 : 0,
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySurface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadius.pill,
                                              ),
                                              border: Border.all(
                                                color: AppColors.primaryLight,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Image captured',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryDark,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
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
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // =====================================================
                        // ACTION BUTTONS
                        // =====================================================

                        const AdBannerWidget(
                          format: AdDisplayFormat.largeBanner,
                          reserveSpaceWhileLoading: true,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            18,
                          ),
                          child: Row(
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
                                    _actionsLocked
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
                                    _actionsLocked ||
                                            _previewImagePath == null
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
                                        .arrow_forward_ios,
                                label:
                                    'Next',
                                primary:
                                    true,
                                onTap:
                                    _actionsLocked ||
                                            _previewImagePath == null
                                        ? null
                                        : _savePhoto,
                              ),
                            ),
                            ],
                          ),
                        ),
                      ],
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
  // SIGNATURE PANEL
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Signature Panel',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AppToggle(
                  value: _showSignatureLabel,
                  onChanged: _isSaving
                      ? null
                      : (enabled) {
                          setState(() {
                            _showSignatureLabel = enabled;
                          });

                          // The signature is part of the final stamped bitmap.
                          // Rebuild the background preparation so Save receives
                          // the latest version, without doing the work on Next.
                          _preparedPhoto = null;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _startPhotoProcessing();
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captureMessageTimer?.cancel();
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foregroundColor =
        !enabled
            ? AppColors.textSecondary
            : primary
            ? Colors.white
            : AppColors.textPrimary;

    return Material(
      color:
          !enabled
              ? AppColors.inactiveSurface
              : primary
              ? AppColors.primary
              : AppColors.surface,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: foregroundColor,
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.caption.copyWith(
                    color: foregroundColor,
                    fontWeight:
                        primary ? FontWeight.w600 : FontWeight.w500,
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
