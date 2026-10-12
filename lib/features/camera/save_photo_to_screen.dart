import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_input_limits.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/services/file_naming_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../projects/create_project_screen.dart';
import '../projects/project_data.dart';
import '../notifications/models/app_notification.dart';
import '../notifications/services/notification_repository.dart';
import '../settings/photo_quality/models/photo_processing_result.dart';

enum PhotoSaveDestination { deviceGallery, projectFolder }

class SavePhotoResult {
  const SavePhotoResult({required this.photo, this.projectId});

  final CapturedPhoto photo;
  final String? projectId;
}

class SavePhotoToScreen extends StatefulWidget {
  const SavePhotoToScreen({
    super.key,
    required this.preparedPhoto,
    required this.previewImagePath,
    required this.originalImagePath,
    required this.location,
    required this.capturedAt,
    required this.stampData,
    this.initialProjectId,
  });

  final Future<PhotoProcessingResult> preparedPhoto;
  final String previewImagePath;
  final String originalImagePath;
  final String location;
  final DateTime capturedAt;
  final GpsStampData stampData;
  final String? initialProjectId;

  @override
  State<SavePhotoToScreen> createState() => _SavePhotoToScreenState();
}

class _SavePhotoToScreenState extends State<SavePhotoToScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  PhotoSaveDestination _destination = PhotoSaveDestination.deviceGallery;
  String? _selectedProjectId;
  String _projectFilter = 'Recent';
  bool _loading = true;
  bool _saving = false;
  bool _preparingPhoto = true;
  PhotoProcessingResult? _processedPhoto;
  String? _preparationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) {
      _destination = PhotoSaveDestination.projectFolder;
      _selectedProjectId = widget.initialProjectId;
    }
    _repository.addListener(_refresh);
    _searchController.addListener(_refresh);
    _load();
    _preparePhoto();
  }

  Future<void> _preparePhoto() async {
    try {
      final result = await widget.preparedPhoto;
      if (!mounted) return;
      setState(() {
        _processedPhoto = result;
        _preparingPhoto = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preparingPhoto = false;
        _preparationError = 'Unable to prepare this photo.';
      });
    }
  }

  Future<void> _load() async {
    await _repository.ensureLoaded(refreshPhotos: true);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  List<ProjectData> get _visibleProjects {
    final query = _searchController.text.trim().toLowerCase();
    final result = _repository.projects.where((project) {
      final statusMatches = _projectFilter == 'All' ||
          (_projectFilter == 'Active' &&
              project.status == ProjectStatus.active) ||
          (_projectFilter == 'Archived' &&
              project.status == ProjectStatus.archived) ||
          _projectFilter == 'Recent';
      final searchMatches = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.code.toLowerCase().contains(query) ||
          project.location.toLowerCase().contains(query);
      return statusMatches && searchMatches;
    }).toList();
    if (_projectFilter == 'Recent' && result.length > 5) {
      return result.take(5).toList();
    }
    return result;
  }

  Future<void> _createProject() async {
    final project = await Navigator.of(context).push<ProjectData>(
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
    if (project == null || !mounted) return;
    setState(() {
      _destination = PhotoSaveDestination.projectFolder;
      _selectedProjectId = project.id;
      _projectFilter = 'Recent';
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_destination == PhotoSaveDestination.projectFolder &&
        _selectedProjectId == null) {
      AppTopToast.show(
        context,
        message: 'Select a project folder first.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Processing may still be running in the background. Do not block the
      // Save Photo screen itself; only wait here if the user saves before the
      // final image is ready. The same in-flight Future is reused.
      final processed = _processedPhoto ?? await widget.preparedPhoto;
      if (!mounted) return;

      if (_processedPhoto == null) {
        setState(() {
          _processedPhoto = processed;
          _preparingPhoto = false;
        });
      }

      final projectId = _destination == PhotoSaveDestination.projectFolder
          ? _selectedProjectId
          : null;
      final project =
          projectId == null ? null : _repository.findById(projectId);
      final extension = processed.path.split('.').last.toLowerCase();
      final fileName = await FileNamingService.createFileName(
        extension: extension,
        projectName: project?.name,
        latitude: widget.stampData.latitude,
        capturedAt: widget.capturedAt,
      );
      final photo = await CapturedPhotoService.saveProcessedPhoto(
        sourcePath: processed.path,
        location: widget.location,
        capturedAt: widget.capturedAt,
        stampData: widget.stampData,
        captureMetadata: processed.metadata,
        projectId: projectId,
        fileName: fileName,
      );

      await CapturedPhotoService.saveToDeviceGallery(
        imagePath: photo.path,
        projectName: project?.name,
      );

      if (projectId != null) {
        await _repository.attachPhoto(projectId, photo);
      }

      if (AppSettingsService.instance.saveOriginalPhoto) {
        final baseName = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        await CapturedPhotoService.saveOriginalToDeviceGallery(
          sourcePath: widget.originalImagePath,
          fileName: '${baseName}_original.png',
          projectName: project?.name,
        );
      }

      try {
        final notificationSettings = AppSettingsService.instance;
        await notificationSettings.ensureNotificationSettingsLoaded();
        if (notificationSettings.masterNotifications &&
            notificationSettings.notifyCaptureSaved) {
          final message = project == null
              ? '$fileName was saved to the device gallery.'
              : '$fileName was saved to Project: ${project.name}.';
          await NotificationRepository.instance.add(
            title: 'Photo saved successfully',
            message: message,
            type: AppNotificationType.photoSaved,
            createdAt: DateTime.now(),
            relatedPhotoId: photo.id,
          );
          await NotificationService.instance.showAppNotification(
            title: 'Photo saved successfully',
            body: message,
            payload: <String, dynamic>{
              'type': 'photoSaved',
              'projectId': projectId,
              'photoId': photo.id,
            },
          );
        }
      } catch (error) {
        debugPrint('Photo saved notification skipped: $error');
      }

      if (!mounted) return;
      Navigator.of(context)
          .pop(SavePhotoResult(photo: photo, projectId: projectId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppTopToast.show(
        context,
        message: 'Unable to save photo: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Save Photo To'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final padding = wide ? 32.0 : AppSpacing.screenPadding;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(padding, 12, padding, 20),
                        children: [
                          _PhotoSummary(
                            imagePath: widget.previewImagePath,
                            location: widget.location,
                            capturedAt: widget.capturedAt,
                          ),
                          if (_preparingPhoto && _preparationError == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Photo is being prepared in the background.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ] else if (_preparationError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _preparationError!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text('Choose a saving location',
                              style: AppTypography.h3),
                          const SizedBox(height: 10),
                          _DestinationTile(
                            icon: Icons.photo_library_outlined,
                            title: 'Device Gallery',
                            subtitle: AppBrand.galleryDisplayPath,
                            selected: _destination ==
                                PhotoSaveDestination.deviceGallery,
                            onTap: () => setState(() => _destination =
                                PhotoSaveDestination.deviceGallery),
                          ),
                          const SizedBox(height: 10),
                          _DestinationTile(
                            icon: Icons.folder_outlined,
                            title: 'Project Folder',
                            subtitle: 'Save under an existing project',
                            selected: _destination ==
                                PhotoSaveDestination.projectFolder,
                            onTap: () => setState(() => _destination =
                                PhotoSaveDestination.projectFolder),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _destination ==
                                    PhotoSaveDestination.projectFolder
                                ? Padding(
                                    key: const ValueKey('project-picker'),
                                    padding: const EdgeInsets.only(top: 18),
                                    child: _buildProjectPicker(),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('no-project-picker'),
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    if (MediaQuery.viewInsetsOf(context).bottom == 0)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 480,
                          ),
                          child: const AdBannerWidget(
                            reserveSpaceWhileLoading: true,
                            slotHeight: 60,
                          ),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.fromLTRB(padding, 10, padding, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border:
                            Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Cancel',
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppPrimaryButton(
                              label: _saving ? 'Saving…' : 'Save Here',
                              onPressed: _saving ? null : _save,
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
    );
  }

  Widget _buildProjectPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text('Select Project Folder', style: AppTypography.h3)),
            DropdownButton<String>(
              value: _projectFilter,
              underline: const SizedBox.shrink(),
              items: const ['Recent', 'All', 'Active', 'Archived']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _projectFilter = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          maxLength: AppInputLimits.search,
          decoration: InputDecoration(
            hintText: 'Search projects',
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_visibleProjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: Text('No matching projects')),
          )
        else
          ..._visibleProjects.map(
            (project) => RadioListTile<String>(
              value: project.id,
              groupValue: _selectedProjectId,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.trailing,
              secondary: Icon(
                Icons.folder_outlined,
                color: Color(project.colorValue),
              ),
              title: Text(project.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${project.photoCount} photos • ${project.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              onChanged: (value) => setState(() => _selectedProjectId = value),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _createProject,
          icon: const Icon(Icons.add),
          label: const Text('Create New Project'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
          ),
        ),
        if (_selectedProjectId != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Saving path\nProjects / ${_repository.findById(_selectedProjectId!)?.name ?? ''}',
              style: AppTypography.caption,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoSummary extends StatelessWidget {
  const _PhotoSummary({
    required this.imagePath,
    required this.location,
    required this.capturedAt,
  });

  final String imagePath;
  final String location;
  final DateTime capturedAt;

  @override
  Widget build(BuildContext context) {
    final date = capturedAt.toLocal();
    final minute = date.minute.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.file(
              File(imagePath),
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 76,
                height: 76,
                color: AppColors.border,
                child: const Icon(Icons.image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $hour:$minute $period',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  Text(subtitle,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
