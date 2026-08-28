

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'services/photo_content_service.dart';
import 'services/photo_pdf_export_service.dart';
import 'services/photo_share_service.dart';
import 'widgets/photo_information_panel.dart';
import 'widgets/photo_location_panel.dart';

enum _VisibleDetailPanel { none, map, information }

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
  _VisibleDetailPanel _visiblePanel = _VisibleDetailPanel.none;
  bool _isDeleting = false;
  bool _isSharing = false;
  bool _isExporting = false;

  bool get _isBusy => _isDeleting || _isSharing || _isExporting;

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

  void _togglePanel(_VisibleDetailPanel panel) {
    if (_isBusy) return;
    setState(() {
      _visiblePanel = _visiblePanel == panel
          ? _VisibleDetailPanel.none
          : panel;
    });
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
        title: 'Share GPS Camera photo',
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
      final content = await PhotoContentService.resolve(
        photo: widget.photo,
        imageAsset: widget.imageAsset,
      );
      final metadata = widget.photo?.captureMetadata;
      final pdfFile = await PhotoPdfExportService.createStampedPhotoPdf(
        content: content,
        capturedAt: _capturedAt,
        imageWidth: metadata?.width,
        imageHeight: metadata?.height,
      );

      await PhotoShareService.shareFile(
        file: pdfFile,
        fileName: pdfFile.uri.pathSegments.last,
        mimeType: 'application/pdf',
        title: 'Export GPS Camera PDF',
        text: 'Stamped GPS Camera photo report',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: $detail')),
    );
  }

  Future<void> _delete() async {
    if (_isBusy) return;
    final photo = widget.photo;

    if (photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample photo cannot be deleted.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
          'This photo will be permanently removed from the app gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);

    try {
      await CapturedPhotoService.deletePhotos(<String>[photo.id]);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _isDeleting = false);
      _showError('Unable to delete photo', error);
    }
  }

  Widget _buildPhoto() {
    final photo = widget.photo;
    if (photo != null) {
      return Image.file(
        File(photo.path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    final asset = widget.imageAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }

    return _imageError();
  }

  Widget _imageError() => Container(
        color: const Color(0xFFEEF2F7),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 54,
          color: Color(0xFF94A3B8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final metadata = widget.photo?.captureMetadata;
    final photoAspectRatio = metadata != null &&
            metadata.width > 0 &&
            metadata.height > 0
        ? metadata.width / metadata.height
        : 4 / 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '',
        actions: [
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: photoAspectRatio,
                        child: _buildPhoto(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: switch (_visiblePanel) {
                          _VisibleDetailPanel.map => Padding(
                              key: const ValueKey<String>('map-detail-panel'),
                              padding: const EdgeInsets.only(top: 16),
                              child: PhotoLocationPanel(
                                location: _location,
                                stampData: _stampData,
                              ),
                            ),
                          _VisibleDetailPanel.information => Padding(
                              key: const ValueKey<String>(
                                'information-detail-panel',
                              ),
                              padding: const EdgeInsets.only(top: 16),
                              child: PhotoInformationPanel(
                                photo: widget.photo,
                                stampData: _stampData,
                                capturedLabel: _capturedLabel,
                              ),
                            ),
                          _VisibleDetailPanel.none => const SizedBox(
                              key: ValueKey<String>('no-detail-panel'),
                              height: 16,
                            ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
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
                      selected: _visiblePanel == _VisibleDetailPanel.map,
                      onTap: _isBusy
                          ? null
                          : () => _togglePanel(_VisibleDetailPanel.map),
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
                      selected:
                          _visiblePanel == _VisibleDetailPanel.information,
                      onTap: _isBusy
                          ? null
                          : () => _togglePanel(
                                _VisibleDetailPanel.information,
                              ),
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
