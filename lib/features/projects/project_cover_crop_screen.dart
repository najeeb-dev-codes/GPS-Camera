import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/constants/project_cover_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

class ProjectCoverCropScreen extends StatefulWidget {
  const ProjectCoverCropScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<ProjectCoverCropScreen> createState() =>
      _ProjectCoverCropScreenState();
}

class _ProjectCoverCropScreenState extends State<ProjectCoverCropScreen> {
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  Size? _imageSize;
  Size? _configuredViewport;
  Size? _cropViewport;
  Object? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      if (mounted) setState(() => _imageSize = size);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  double _coverScale(Size viewport) {
    final imageSize = _imageSize!;
    return math.max(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
  }

  void _configureTransform(Size viewport) {
    if (_imageSize == null || _configuredViewport == viewport) return;
    _configuredViewport = viewport;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scale = _coverScale(viewport);
      final imageSize = _imageSize!;
      final left = (viewport.width - (imageSize.width * scale)) / 2;
      final top = (viewport.height - (imageSize.height * scale)) / 2;
      _transformationController.value = Matrix4.identity()
        ..translate(left, top)
        ..scale(scale);
    });
  }

  /// Clamps [value] to [lower]..[upper] without ever throwing, and falls
  /// back to [upper] if the value is NaN or infinite.
  double _safeClamp(double value, double lower, double upper) {
    if (!value.isFinite) return upper;
    final low = math.min(lower, upper);
    final high = math.max(lower, upper);
    return value.clamp(low, high).toDouble();
  }

  void _keepImageInsideCrop(Size viewport) {
    final imageSize = _imageSize;
    if (imageSize == null) return;

    final minimumScale = _coverScale(viewport);
    final current = _transformationController.value;
    final scale = current
        .getMaxScaleOnAxis()
        .clamp(minimumScale, minimumScale * 6)
        .toDouble();
    // When the image exactly fills the crop area, floating-point rounding can
    // make these values a tiny positive number (for example 5.7e-14).
    // `clamp` throws if its lower bound is above its upper bound, so the lower
    // bound is always limited to 0.
    final minimumX = math.min(0.0, viewport.width - (imageSize.width * scale));
    final minimumY =
        math.min(0.0, viewport.height - (imageSize.height * scale));
    final left = _safeClamp(current.storage[12], minimumX, 0.0);
    final top = _safeClamp(current.storage[13], minimumY, 0.0);

    _transformationController.value = Matrix4.identity()
      ..translate(left, top)
      ..scale(scale);
  }

  Future<void> _saveCrop() async {
    final viewport = _cropViewport;
    if (_saving || viewport == null) return;

    setState(() => _saving = true);
    try {
      _keepImageInsideCrop(viewport);
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _cropBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Crop preview is not ready.');

      final pixelRatio = ProjectCoverLayout.outputWidth / viewport.width;
      final croppedImage = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();
      if (byteData == null) throw StateError('Unable to create cropped image.');

      final source = File(widget.imagePath);
      final output = File(
        '${source.parent.path}/project_cover_crop_'
        '${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await output.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(output.path);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppTopToast.show(
        context,
        message: 'Unable to crop cover image: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop project cover'),
        actions: [
          TextButton(
            onPressed: _saving || _imageSize == null ? null : _saveCrop,
            child: Text(
              _saving ? 'Saving…' : 'Apply',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Unable to open this image.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0.0, constraints.maxWidth - 24);
        final availableHeight = math.max(0.0, constraints.maxHeight - 112);
        var width = availableWidth;
        var height = width / ProjectCoverLayout.aspectRatio;
        if (height > availableHeight) {
          height = availableHeight;
          width = height * ProjectCoverLayout.aspectRatio;
        }
        final viewport = Size(width, height);
        _cropViewport = viewport;
        _configureTransform(viewport);
        final minimumScale = _coverScale(viewport);

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Text(
                'Pinch to zoom and drag to choose the visible cover area.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox.fromSize(
                  size: viewport,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        key: _cropBoundaryKey,
                        child: ClipRect(
                          child: ColoredBox(
                            color: Colors.black,
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              constrained: false,
                              boundaryMargin:
                                  const EdgeInsets.all(double.infinity),
                              minScale: minimumScale,
                              maxScale: minimumScale * 6,
                              onInteractionEnd: (_) =>
                                  _keepImageInsideCrop(viewport),
                              child: SizedBox(
                                width: _imageSize!.width,
                                height: _imageSize!.height,
                                child: Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: const _CropGridPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _saveCrop,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(_saving ? 'Saving…' : 'Apply Crop'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CropGridPainter extends CustomPainter {
  const _CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var index = 1; index < 3; index++) {
      final x = size.width * index / 3;
      final y = size.height * index / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}