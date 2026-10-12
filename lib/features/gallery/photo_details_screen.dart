import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../projects/project_data.dart';
import 'services/photo_content_service.dart';
import 'services/photo_pdf_export_service.dart';
import 'services/photo_share_service.dart';
import './widgets/photo_information_panel.dart';
import './widgets/photo_location_panel.dart';


class PhotoDetailsScreen extends StatefulWidget {
  const PhotoDetailsScreen({
    super.key,
    this.photo,
    this.imageAsset,
    this.locationLabel,
    this.timestampLabel,
  });

  final CapturedPhoto? photo;
  final String? imageAsset;
  final String? locationLabel;
  final String? timestampLabel;

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  static const double _minimumPhotoScale = 1;
  static const double _maximumPhotoScale = 8;

  bool _isDeleting = false;
  bool _isSharing = false;
  bool _isExporting = false;
  bool _isUpdatingFavorite = false;
  bool _isMoving = false;
  late bool _isFavorite;
  String? _currentProjectId;
  bool _isPhotoZoomed = false;
  double _photoScale = _minimumPhotoScale;
  Offset _photoOffset = Offset.zero;
  double _gestureStartScale = _minimumPhotoScale;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  double? _decodedPhotoAspectRatio;
  ImageStream? _photoImageStream;
  ImageStreamListener? _photoImageListener;

  bool get _isBusy =>
      _isDeleting ||
      _isSharing ||
      _isExporting ||
      _isUpdatingFavorite ||
      _isMoving;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.photo?.isFavorite ?? false;
    _currentProjectId = widget.photo?.projectId;
    _resolvePhotoAspectRatio();
  }

  void _resolvePhotoAspectRatio() {
    final ImageProvider<Object>? provider;
    if (widget.photo != null) {
      provider = FileImage(File(widget.photo!.path));
    } else if (widget.imageAsset != null) {
      provider = AssetImage(widget.imageAsset!);
    } else {
      provider = null;
    }

    if (provider == null) return;

    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, _) {
        stream.removeListener(listener);
        if (!mounted || imageInfo.image.height <= 0) return;

        final ratio = imageInfo.image.width / imageInfo.image.height;
        if (!ratio.isFinite || ratio <= 0) return;
        setState(() => _decodedPhotoAspectRatio = ratio);
      },
      onError: (_, __) => stream.removeListener(listener),
    );

    _photoImageStream = stream;
    _photoImageListener = listener;
    stream.addListener(listener);
  }

  Offset _clampPhotoOffset({
    required Offset offset,
    required double scale,
    required Size fittedPhotoSize,
    required Size viewportSize,
  }) {
    final maximumX = math.max(
      0.0,
      ((fittedPhotoSize.width * scale) - viewportSize.width) / 2,
    );
    final maximumY = math.max(
      0.0,
      ((fittedPhotoSize.height * scale) - viewportSize.height) / 2,
    );

    return Offset(
      offset.dx.clamp(-maximumX, maximumX).toDouble(),
      offset.dy.clamp(-maximumY, maximumY).toDouble(),
    );
  }

  void _startPhotoGesture(
    ScaleStartDetails details,
    Size fittedPhotoSize,
    Size viewportSize,
  ) {
    _gestureStartScale = _photoScale;
    _gestureStartOffset = _clampPhotoOffset(
      offset: _photoOffset,
      scale: _photoScale,
      fittedPhotoSize: fittedPhotoSize,
      viewportSize: viewportSize,
    );
    _photoOffset = _gestureStartOffset;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  void _updatePhotoGesture(
    ScaleUpdateDetails details,
    Size fittedPhotoSize,
    Size viewportSize,
  ) {
    final nextScale = (_gestureStartScale * details.scale)
        .clamp(_minimumPhotoScale, _maximumPhotoScale)
        .toDouble();
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final scaleChange = nextScale / _gestureStartScale;

    // Keep the point below the fingers stationary during pinch zoom. For a
    // one-finger gesture the same calculation becomes normal free panning.
    final requestedOffset = details.localFocalPoint -
        viewportCenter -
        ((_gestureStartFocalPoint -
                viewportCenter -
                _gestureStartOffset) *
            scaleChange);
    final nextOffset = _clampPhotoOffset(
      offset: requestedOffset,
      scale: nextScale,
      fittedPhotoSize: fittedPhotoSize,
      viewportSize: viewportSize,
    );

    setState(() {
      _photoScale = nextScale;
      _photoOffset = nextOffset;
      _isPhotoZoomed = nextScale > 1.01;
    });
  }

  void _finishPhotoGesture(
    ScaleEndDetails _,
    Size fittedPhotoSize,
    Size viewportSize,
  ) {
    if (_photoScale <= 1.02) {
      setState(() {
        _photoScale = _minimumPhotoScale;
        _photoOffset = Offset.zero;
        _isPhotoZoomed = false;
      });
      return;
    }

    setState(() {
      _photoOffset = _clampPhotoOffset(
        offset: _photoOffset,
        scale: _photoScale,
        fittedPhotoSize: fittedPhotoSize,
        viewportSize: viewportSize,
      );
      _isPhotoZoomed = true;
    });
  }

  @override
  void dispose() {
    final stream = _photoImageStream;
    final listener = _photoImageListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    super.dispose();
  }

  String _formatCapturedDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '${value.day} ${months[value.month - 1]} ${value.year} • '
        '$hour:$minute $period';
  }

  GpsStampData get _stampData {
    final photo = widget.photo;
    if (photo?.stampData != null) return photo!.stampData!;
    if (photo != null) {
      return GpsStampData(
        address: photo.location,
        dateTime: _formatCapturedDate(photo.capturedAt),
      );
    }

    return GpsStampData(
      address: widget.locationLabel ?? 'Location unavailable',
      dateTime: widget.timestampLabel,
    );
  }

  String get _location =>
      widget.photo?.location ?? widget.locationLabel ?? _stampData.address;

  String get _capturedLabel {
    final photo = widget.photo;
    if (photo != null) return _formatCapturedDate(photo.capturedAt);
    return widget.timestampLabel ?? _stampData.dateTime ?? '—';
  }

  DateTime get _capturedAt => widget.photo?.capturedAt ?? DateTime.now();

  Rect? _shareOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _openLocationScreen() async {
    if (_isBusy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoLocationPanel(
          location: _location,
          stampData: _stampData,
        ),
      ),
    );
  }

  Future<void> _openInformationScreen() async {
    if (_isBusy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoInformationPanel(
          photo: widget.photo,
          stampData: _stampData,
        ),
      ),
    );
  }

  Future<void> _sharePhoto() async {
    if (_isBusy) return;
    setState(() => _isSharing = true);

    try {
      final content = await PhotoContentService.resolve(
        photo: widget.photo,
        imageAsset: widget.imageAsset,
      );

      await PhotoShareService.shareFile(
        file: content.file,
        fileName: content.fileName,
        mimeType: content.mimeType,
        title: 'Share ${AppBrand.name} photo',
        text: _location,
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (error) {
      _showError('Unable to share photo', error);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_isBusy) return;
    setState(() => _isExporting = true);

    try {
      await AdService.instance.showInterstitialIfReady();
      if (!mounted) return;

      final content = await PhotoContentService.resolve(
        photo: widget.photo,
        imageAsset: widget.imageAsset,
      );
      final metadata = widget.photo?.captureMetadata;
      final projectRepository = ProjectRepository.instance;
      await projectRepository.ensureLoaded();
      final projectName = _currentProjectId == null
          ? null
          : projectRepository.findById(_currentProjectId!)?.name;
      final pdfFile = await PhotoPdfExportService.createStampedPhotoPdf(
        content: content,
        capturedAt: _capturedAt,
        projectName: projectName,
        imageWidth: metadata?.width,
        imageHeight: metadata?.height,
      );

      await PhotoShareService.shareFile(
        file: pdfFile,
        fileName: pdfFile.uri.pathSegments.last,
        mimeType: 'application/pdf',
        title: 'Export ${AppBrand.name} PDF',
        text: 'Stamped ${AppBrand.name} photo report',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (error) {
      _showError('Unable to export PDF', error);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showError(String message, Object error) {
    if (!mounted) return;
    final detail = error.toString().replaceFirst('Exception: ', '');
    AppTopToast.show(
      context,
      message: '$message: $detail',
      icon: Icons.error_outline_rounded,
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isBusy) return;
    final photo = widget.photo;
    if (photo == null) {
      AppTopToast.show(
        context,
        message: 'Sample photos cannot be favorited.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final nextValue = !_isFavorite;
    setState(() => _isUpdatingFavorite = true);
    try {
      await CapturedPhotoService.setFavorite(
        <String>[photo.id],
        favorite: nextValue,
      );
      if (mounted) {
        setState(() {
          _isFavorite = nextValue;
          _isUpdatingFavorite = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _isUpdatingFavorite = false);
      _showError('Unable to update favorite', error);
    }
  }

  Future<void> _moveToProject() async {
    if (_isBusy) return;
    final photo = widget.photo;
    if (photo == null) return;

    final repository = ProjectRepository.instance;
    await repository.ensureLoaded(refreshPhotos: true);
    if (!mounted) return;

    final project = await showModalBottomSheet<ProjectData>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final projects = repository.projects
            .where(
              (item) =>
                  item.status == ProjectStatus.active &&
                  item.id != _currentProjectId,
            )
            .toList(growable: false);

        return SafeArea(
          child: projects.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: EmptyStatePlaceholder(
                    icon: Icons.folder_open_outlined,
                    title: 'No other active projects',
                    description:
                        'Create or restore another project before moving this photo.',
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: <Widget>[
                    const ListTile(
                      title: Text(
                        'Move to project',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ...projects.map(
                      (item) => ListTile(
                        leading: Icon(
                          Icons.folder_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.photoCount} photos • ${item.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(item),
                      ),
                    ),
                  ],
                ),
        );
      },
    );

    if (project == null || !mounted) return;
    setState(() => _isMoving = true);

    try {
      final movedPhotos = await CapturedPhotoService.moveToProject(
        <String>[photo.id],
        projectId: project.id,
      );
      await repository.movePhotosToProject(project.id, movedPhotos);
      if (!mounted) return;
      setState(() {
        _currentProjectId = project.id;
        _isMoving = false;
      });
      AppTopToast.show(
        context,
        message: 'Photo moved to ${project.name}.',
        icon: Icons.drive_file_move_outline,
      );
    } catch (error) {
      if (mounted) setState(() => _isMoving = false);
      _showError('Unable to move photo', error);
    }
  }

  Future<void> _delete() async {
    if (_isBusy) return;
    final photo = widget.photo;

    if (photo == null) {
      AppTopToast.show(
        context,
        message: 'Sample photo cannot be deleted.',
        icon: Icons.info_outline_rounded,
        backgroundColor: Colors.red,
      );
      return;
    }

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete photo?',
      message: 'This photo will be permanently removed from the app gallery.',
    );

    if (!confirmed || !mounted) return;
    setState(() => _isDeleting = true);

    try {
      await CapturedPhotoService.deletePhotos(<String>[photo.id]);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Photo deleted successfully.',
        icon: Icons.delete_outline_rounded,
        backgroundColor: Colors.red,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _isDeleting = false);
      _showError('Unable to delete photo', error);
    }
  }

  Widget _buildPhoto({BoxFit fit = BoxFit.contain}) {
    final photo = widget.photo;
    if (photo != null) {
      return Image.file(
        File(photo.path),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    final asset = widget.imageAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    return _imageError();
  }

  Widget _imageError() => Container(
        color: AppColors.mutedSurface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 54,
          color: Color(0xFF94A3B8),
        ),
      );

  Widget _buildZoomablePhoto({required double photoAspectRatio}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;

        if (!viewportWidth.isFinite ||
            !viewportHeight.isFinite ||
            viewportWidth <= 0 ||
            viewportHeight <= 0) {
          return const SizedBox.shrink();
        }

        // Calculate boundaries from the real contained-photo rectangle, not
        // from an invisible full-screen child. This keeps left/right and
        // top/bottom movement symmetrical and prevents exposed empty space.
        final fittedSize = applyBoxFit(
          BoxFit.contain,
          Size(photoAspectRatio, 1),
          Size(viewportWidth, viewportHeight),
        ).destination;

        final viewportSize = Size(viewportWidth, viewportHeight);
        final visibleOffset = _clampPhotoOffset(
          offset: _photoOffset,
          scale: _photoScale,
          fittedPhotoSize: fittedSize,
          viewportSize: viewportSize,
        );

        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) => _startPhotoGesture(
              details,
              fittedSize,
              viewportSize,
            ),
            onScaleUpdate: (details) => _updatePhotoGesture(
              details,
              fittedSize,
              viewportSize,
            ),
            onScaleEnd: (details) => _finishPhotoGesture(
              details,
              fittedSize,
              viewportSize,
            ),
            child: Transform.translate(
              offset: visibleOffset,
              child: Transform.scale(
                scale: _photoScale,
                alignment: Alignment.center,
                child: RepaintBoundary(
                  child: SizedBox.expand(
                    child: _buildPhoto(fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.photo?.captureMetadata;
    final metadataAspectRatio = metadata != null &&
            metadata.width > 0 &&
            metadata.height > 0
        ? metadata.width / metadata.height
        : 4 / 3;
    final photoAspectRatio =
        _decodedPhotoAspectRatio ?? metadataAspectRatio;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: '',
        actions: [
          IconButton(
            tooltip: _isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: _isBusy ? null : _toggleFavorite,
            icon: _isUpdatingFavorite
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: _isFavorite
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
          ),
          if (widget.photo != null)
            IconButton(
              tooltip: 'Move to project',
              onPressed: _isBusy ? null : _moveToProject,
              icon: _isMoving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.drive_file_move_outline),
            ),
          IconButton(
            tooltip: 'Delete photo',
            onPressed: _isBusy ? null : _delete,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox.expand(
          child: _buildZoomablePhoto(
            photoAspectRatio: photoAspectRatio,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ActionColumn(
                      icon: Icons.map_outlined,
                      label: 'Open in Maps',
                      onTap: _isBusy ? null : _openLocationScreen,
                    ),
                  ),
                  Expanded(
                    child: _ActionColumn(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      loading: _isSharing,
                      onTap: _isBusy ? null : _sharePhoto,
                    ),
                  ),
                  Expanded(
                    child: _ActionColumn(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Export Report',
                      loading: _isExporting,
                      onTap: _isBusy ? null : _exportPdf,
                    ),
                  ),
                  Expanded(
                    child: _ActionColumn(
                      icon: Icons.info_outline_rounded,
                      label: 'Information',
                      onTap: _isBusy ? null : _openInformationScreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionColumn extends StatelessWidget {
  const _ActionColumn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tint = onTap == null && !loading
        ? AppColors.textSecondary
        : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: selected ? 0.16 : 0.08),
                shape: BoxShape.circle,
                border: selected ? Border.all(color: tint) : null,
              ),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tint,
                      ),
                    )
                  : Icon(icon, color: tint, size: AppSizes.iconMd),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppTypography.tiny.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}