import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../gallery/photo_details_screen.dart';
import 'project_data.dart';

class ProjectPhotosScreen extends StatefulWidget {
  const ProjectPhotosScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectPhotosScreen> createState() => _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState extends State<ProjectPhotosScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  final LinkedHashSet<String> _selectedIds = LinkedHashSet<String>();
  bool _loading = true;
  bool _sharing = false;

  ProjectData? get _project => _repository.findById(widget.projectId);
  bool get _selecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await _repository.ensureLoaded(refreshPhotos: true);
    if (mounted) setState(() => _loading = false);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  int? _selectionNumber(String id) {
    final index = _selectedIds.toList(growable: false).indexOf(id);
    return index < 0 ? null : index + 1;
  }

  String _dateLabel(DateTime value) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = value.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  List<MapEntry<String, List<CapturedPhoto>>> _groupByDate(
    List<CapturedPhoto> photos,
  ) {
    final groups = LinkedHashMap<String, List<CapturedPhoto>>();
    for (final photo in photos) {
      groups.putIfAbsent(_dateLabel(photo.capturedAt), () => []).add(photo);
    }
    return groups.entries.toList(growable: false);
  }

  bool _isGroupSelected(List<CapturedPhoto> photos) =>
      photos.isNotEmpty &&
      photos.every((photo) => _selectedIds.contains(photo.id));

  void _toggleDateGroup(List<CapturedPhoto> photos) {
    final select = !_isGroupSelected(photos);
    setState(() {
      for (final photo in photos) {
        if (select) {
          _selectedIds.add(photo.id);
        } else {
          _selectedIds.remove(photo.id);
        }
      }
    });
  }

  bool _areAllPhotosSelected(List<CapturedPhoto> photos) =>
      photos.isNotEmpty &&
      photos.every((photo) => _selectedIds.contains(photo.id));

  void _toggleAllPhotos(List<CapturedPhoto> photos) {
    final select = !_areAllPhotosSelected(photos);
    setState(() {
      if (select) {
        _selectedIds
          ..clear()
          ..addAll(photos.map((photo) => photo.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  Widget _buildPhotoTile(CapturedPhoto photo) {
    final number = _selectionNumber(photo.id);
    return GestureDetector(
      onTap: () => _openPhoto(photo),
      onLongPress: () => _toggle(photo.id),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.mutedSurface,
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined),
              ),
            ),
            if (number != null)
              Container(color: AppColors.primary.withValues(alpha: 0.22)),
            if (number != null)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '$number',
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhoto(CapturedPhoto photo) async {
    if (_selecting) {
      _toggle(photo.id);
      return;
    }
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PhotoDetailsScreen(photo: photo)),
    );
    if (deleted == true) await _load();
  }

  Rect? _shareOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _shareSelected() async {
    if (_sharing || _selectedIds.isEmpty) return;
    final project = _project;
    if (project == null) return;
    final files = project.photos
        .where((photo) => _selectedIds.contains(photo.id))
        .map((photo) => File(photo.path))
        .where((file) => file.existsSync())
        .map((file) => XFile(file.path))
        .toList();
    if (files.isEmpty) {
      AppTopToast.show(
        context,
        message: 'Selected photo files are unavailable.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    setState(() => _sharing = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: '${project.name} photos',
          subject: '${project.name} project photos',
          files: files,
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (error) {
      if (mounted) {
        AppTopToast.show(
          context,
          message: 'Unable to share photos: $error',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final dateGroups = project == null
        ? <MapEntry<String, List<CapturedPhoto>>>[]
        : _groupByDate(project.photos);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          _selecting
              ? '${_selectedIds.length} selected'
              : '${project?.name ?? 'Project'} Photos',
        ),
        leading: _selecting
            ? IconButton(
                onPressed: () => setState(() => _selectedIds.clear()),
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          if (project != null && dateGroups.length > 1)
            IconButton(
              tooltip: _areAllPhotosSelected(project.photos)
                  ? 'Clear selection'
                  : 'Multiple select',
              onPressed: () => _toggleAllPhotos(project.photos),
              icon: Icon(
                _areAllPhotosSelected(project.photos)
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
              ),
            ),
          if (_selecting)
            PopupMenuButton<String>(
              enabled: !_sharing,
              onSelected: (value) {
                if (value == 'share') _shareSelected();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.ios_share_outlined),
                    title: Text('Share selected'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
              ? const EmptyStatePlaceholder(
                  icon: Icons.folder_off_outlined,
                  title: 'Project not found',
                  description: 'This project is no longer available.',
                )
              : project.photos.isEmpty
                  ? const Align(
                      alignment: Alignment.topCenter,
                      child: EmptyStatePlaceholder(
                        icon: Icons.photo_library_outlined,
                        title: 'No project photos',
                        description:
                            'Photos saved to this project appear here.',
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 6
                            : constraints.maxWidth >= 600
                                ? 4
                                : 3;
                        final horizontalPadding = constraints.maxWidth >= 600
                            ? 32.0
                            : AppSpacing.screenPadding;
                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            AppSpacing.sm,
                            horizontalPadding,
                            AppSpacing.xxl,
                          ),
                          children: [
                            for (final group in dateGroups) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.key,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (group.value.length > 1)
                                      Material(
                                        color: AppColors.primarySurface,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () =>
                                              _toggleDateGroup(group.value),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(
                                              _isGroupSelected(group.value)
                                                  ? Icons.check_rounded
                                                  : Icons
                                                      .library_add_check_outlined,
                                              size: 19,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  // Photo thumbnails should remain square on all screen sizes.
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: group.value.length,
                                itemBuilder: (_, index) =>
                                    _buildPhotoTile(group.value[index]),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        );
                      },
                    ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}
