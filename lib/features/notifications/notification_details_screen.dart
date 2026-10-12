import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../gallery/photo_details_screen.dart';
import 'models/app_notification.dart';
import 'services/notification_repository.dart';

class NotificationDetailsScreen extends StatefulWidget {
  const NotificationDetailsScreen({
    super.key,
    required this.notification,
  });

  final AppNotification notification;

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  CapturedPhoto? _photo;
  bool _loadingPhoto = false;
  bool _deleting = false;

  bool get _isPhotoNotification =>
      widget.notification.type == AppNotificationType.photoSaved;

  bool get _canViewPhoto => _isPhotoNotification && _photo != null;

  @override
  void initState() {
    super.initState();
    _loadRelatedPhoto();
  }

  Future<void> _loadRelatedPhoto() async {
    final photoId = widget.notification.relatedPhotoId;
    if (!_isPhotoNotification || photoId == null || photoId.isEmpty) return;

    setState(() => _loadingPhoto = true);
    final photos = await CapturedPhotoService.loadPhotos();
    CapturedPhoto? match;
    for (final photo in photos) {
      if (photo.id == photoId) {
        match = photo;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _photo = match;
      _loadingPhoto = false;
    });
  }

  (IconData, Color) get _visual => switch (widget.notification.type) {
        AppNotificationType.photoSaved =>
          (Icons.photo_camera_outlined, AppColors.green),
        AppNotificationType.permission =>
          (Icons.location_on_outlined, AppColors.blue),
        AppNotificationType.storage =>
          (Icons.storage_outlined, AppColors.orange),
        AppNotificationType.project =>
          (Icons.folder_copy_outlined, AppColors.primary),
        AppNotificationType.general =>
          (Icons.notifications_outlined, AppColors.textSecondary),
      };

  String _dateTimeLabel(DateTime value) {
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
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} ${months[local.month - 1]} ${local.year}, '
        '$hour:$minute $period';
  }

  String get _fileName {
    final path = _photo?.path.replaceAll('\\', '/');
    if (path == null || path.isEmpty) return 'Unavailable';
    return path.split('/').last;
  }

  Future<void> _viewPhoto() async {
    final photo = _photo;
    if (photo == null || !await File(photo.path).exists()) {
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'This photo is no longer available.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoDetailsScreen(photo: photo)),
    );
  }

  Future<void> _deleteNotification() async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete notification?',
      message: 'This notification will be permanently removed.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await NotificationRepository.instance.delete(widget.notification.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppTopToast.show(
        context,
        message: 'Unable to delete notification.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, accent) = _visual;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Notification Details'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.xxl,
                          horizontalPadding,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.10),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              alignment: Alignment.center,
                              child: Icon(icon, color: accent, size: 34),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              widget.notification.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.h2.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.80,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.notification.message,
                                    style: AppTypography.body.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (_photo != null) ...[
                                    const SizedBox(height: AppSpacing.lg),
                                    Divider(color: colors.outlineVariant),
                                    _DetailRow(
                                      icon: Icons.insert_drive_file_outlined,
                                      label: 'File name',
                                      value: _fileName,
                                    ),
                                    _DetailRow(
                                      icon: Icons.location_on_outlined,
                                      label: 'Location',
                                      value: _photo!.location,
                                    ),
                                    _DetailRow(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Captured',
                                      value: _dateTimeLabel(
                                        _photo!.capturedAt,
                                      ),
                                    ),
                                    _DetailRow(
                                      icon: Icons.folder_outlined,
                                      label: 'Saved to',
                                      value: _photo!.projectId == null
                                          ? 'Device Gallery'
                                          : 'Project folder',
                                      showDivider: false,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _dateTimeLabel(widget.notification.createdAt),
                              style: AppTypography.caption.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.sm,
                        horizontalPadding,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          if (_loadingPhoto)
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: LinearProgressIndicator(),
                            ),
                          if (_canViewPhoto) ...[
                            AppPrimaryButton(
                              label: 'View Photo',
                              icon: Icons.photo_outlined,
                              onPressed: _viewPhoto,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          AppSecondaryButton(
                            label: 'Delete Notification',
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            outlined: true,
                            onPressed:
                                _deleting ? null : _deleteNotification,
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
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: -1,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppSizes.iconSm, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 82,
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTypography.body.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: colors.outlineVariant),
      ],
    );
  }
}
