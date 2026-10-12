import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_brand.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'photo_details_screen.dart';
import '../projects/project_data.dart';

// =============================================================================
// GROUPING MODE / GROUP MODEL
// =============================================================================

/// How the photos of a gallery view are grouped (the "Filter" button).
enum _GroupMode { date, project }

class _PhotoGroup {
  const _PhotoGroup({
    required this.title,
    required this.photos,
  });

  final String title;
  final List<_GalleryPhoto> photos;
}

// =============================================================================
// GALLERY PHOTO MODEL
// =============================================================================

class _GalleryPhoto {
  const _GalleryPhoto({
    required this.id,
    this.imageAsset,
    this.imagePath,
    required this.locationLabel,
    required this.timestampLabel,
    required this.dateGroup,
    required this.capturedAt,
    this.projectId,
    this.projectName,
    this.projectColorValue,
    this.isFavorite = false,
    this.capturedPhoto,
  });

  final String id;

  final String? imageAsset;
  final String? imagePath;

  final String locationLabel;
  final String timestampLabel;
  final String dateGroup;
  final DateTime capturedAt;

  final String? projectId;
  final String? projectName;

  /// Project colour picked by the user (ARGB int), null when no project.
  final int? projectColorValue;

  final bool isFavorite;

  /// Original captured photo.
  ///
  /// Non-null only for actual camera captures.
  final CapturedPhoto? capturedPhoto;
}

// =============================================================================
// GALLERY SCREEN
// =============================================================================

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    super.key,
    this.dateGroup,
    this.photoIds,
    this.title,
  });

  final String? dateGroup;
  final Set<String>? photoIds;
  final String? title;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const List<String> _mainTabs = [
    'Gallery',
    'Project',
    'Favorites',
  ];

  static const List<String> _favoriteTabs = [
    'Gallery',
    'Project',
  ];

  final Set<String> _selectedIds = <String>{};

  final List<_GalleryPhoto> _photos = <_GalleryPhoto>[];

  /// Main tab: 0 Gallery, 1 Project, 2 Favorites.
  int _tabIndex = 0;

  /// Favorites sub tab: 0 Gallery, 1 Project.
  int _favoriteTabIndex = 0;

  /// Grouping per view: [Gallery, Project, Favorites/Gallery, Favorites/Project].
  /// Default is date wise; the Filter button switches to project name wise.
  final List<_GroupMode> _groupModes =
      List<_GroupMode>.filled(4, _GroupMode.date);

  bool _loading = true;

  /// True for the main gallery (tabs). False when this screen is opened for a
  /// specific date/photo list (plain photo grid).
  bool get _isRoot => widget.dateGroup == null && widget.photoIds == null;

  /// 0 Gallery, 1 Project, 2 Favorites/Gallery, 3 Favorites/Project.
  int get _viewIndex => _tabIndex == 2 ? 2 + _favoriteTabIndex : _tabIndex;

  /// The Filter (date wise / project name wise) exists only in the Project
  /// views. Gallery views are always date wise.
  _GroupMode get _groupMode =>
      _isProjectView ? _groupModes[_viewIndex] : _GroupMode.date;

  bool get _isProjectView => _viewIndex == 1 || _viewIndex == 3;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadCapturedPhotos();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    super.dispose();
  }

  // ===========================================================================
  // LOAD REAL CAPTURED PHOTOS
  // ===========================================================================

  Future<void> _loadCapturedPhotos({bool showLoading = true}) async {
    try {
      if (showLoading && mounted) {
        setState(() {
          _loading = true;
        });
      }

      await ProjectRepository.instance.ensureLoaded(refreshPhotos: true);

      final capturedPhotos = await CapturedPhotoService.loadPhotos();

      debugPrint(
        'Gallery captured photo count: '
        '${capturedPhotos.length}',
      );

      for (final photo in capturedPhotos) {
        debugPrint(
          'Gallery image: ${photo.path}',
        );

        debugPrint(
          'Exists: '
          '${File(photo.path).existsSync()}',
        );
      }

      if (!mounted) return;

      setState(() {
        _photos.clear();

        // =============================================================
        // REAL CAPTURED IMAGES ONLY
        // =============================================================

        final sortedPhotos = List<CapturedPhoto>.of(capturedPhotos)
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

        _photos.addAll(
          sortedPhotos.map(
            (photo) => _GalleryPhoto(
              id: photo.id,

              imagePath: photo.path,

              locationLabel: photo.location,

              timestampLabel: _timeLabel(
                photo.capturedAt,
              ),

              dateGroup: _dateLabel(
                photo.capturedAt,
              ),

              capturedAt: photo.capturedAt,

              projectId: photo.projectId,

              projectColorValue: photo.projectId == null
                  ? null
                  : ProjectRepository.instance
                      .findById(photo.projectId!)
                      ?.colorValue,

              projectName: photo.projectId == null
                  ? null
                  : ProjectRepository.instance
                          .findById(photo.projectId!)
                          ?.name ??
                      'Project',

              isFavorite: photo.isFavorite,

              // IMPORTANT
              //
              // Keep original object so
              // PhotoDetailsScreen can:
              //
              // - display real file
              // - know photo ID
              // - delete correct photo
              capturedPhoto: photo,
            ),
          ),
        );

        _selectedIds.clear();
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Gallery load error: $e',
      );

      if (!mounted) return;

      setState(() {
        _photos.clear();

        _selectedIds.clear();
        _loading = false;
      });
    }
  }

  // ===========================================================================
  // TIME FORMAT
  // ===========================================================================

  String _timeLabel(
    DateTime value,
  ) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;

    final minute = value.minute.toString().padLeft(
          2,
          '0',
        );

    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _dateLabel(
    DateTime value,
  ) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day-$month-${local.year}';
  }

  // ===========================================================================
  // SELECTION STATE
  // ===========================================================================

  bool get _isSelecting => _selectedIds.isNotEmpty;

  // ===========================================================================
  // FILTERED PHOTOS
  // ===========================================================================

  List<_GalleryPhoto> get _visiblePhotos {
    // Drill-down screens (date / photo list) show every matching photo.
    final view = _isRoot ? _viewIndex : -1;

    return _photos.where(
      (photo) {
        if (widget.dateGroup != null && photo.dateGroup != widget.dateGroup) {
          return false;
        }
        if (widget.photoIds != null && !widget.photoIds!.contains(photo.id)) {
          return false;
        }

        switch (view) {
          case 0: // Gallery: only photos that are not in any project
            return photo.projectId == null;

          case 1: // Project: only photos that belong to a project
            return photo.projectId != null;

          case 2: // Favorites / Gallery: bookmarked, not in a project
            return photo.isFavorite && photo.projectId == null;

          case 3: // Favorites / Project: bookmarked, in a project
            return photo.isFavorite && photo.projectId != null;

          default:
            return true;
        }
      },
    ).toList();
  }

  // ===========================================================================
  // GROUPS (date wise / project name wise)
  // ===========================================================================

  List<_PhotoGroup> _buildGroups(List<_GalleryPhoto> photos) {
    if (_groupMode == _GroupMode.date) {
      final byDate = <String, List<_GalleryPhoto>>{};

      // Photos are already newest first, so dates stay newest first and the
      // photos inside each date stay newest first too.
      for (final photo in photos) {
        byDate.putIfAbsent(photo.dateGroup, () => <_GalleryPhoto>[]).add(photo);
      }

      return byDate.entries
          .map(
            (entry) => _PhotoGroup(
              title: entry.key,
              photos: entry.value,
            ),
          )
          .toList(growable: false);
    }

    final byProject = <String, List<_GalleryPhoto>>{};

    for (final photo in photos) {
      byProject
          .putIfAbsent(photo.projectId ?? '', () => <_GalleryPhoto>[])
          .add(photo);
    }

    String nameOf(String key) =>
        (byProject[key]!.first.projectName ?? '').toLowerCase();

    // Projects A-Z; photos that are not in a project go last.
    final keys = byProject.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return b.isEmpty ? 0 : 1;
        if (b.isEmpty) return -1;
        return nameOf(a).compareTo(nameOf(b));
      });

    return keys
        .map(
          (key) => _PhotoGroup(
            title: key.isEmpty
                ? 'No project'
                : (byProject[key]!.first.projectName ?? 'Project'),
            photos: byProject[key]!,
          ),
        )
        .toList(growable: false);
  }

  // ===========================================================================
  // TOGGLE SELECTION
  // ===========================================================================

  void _toggleSelection(
    String id,
  ) {
    setState(() {
      if (_selectedIds.contains(
        id,
      )) {
        _selectedIds.remove(
          id,
        );
      } else {
        _selectedIds.add(
          id,
        );
      }
    });
  }

  int? _selectionNumber(String id) {
    final index = _selectedIds.toList(growable: false).indexOf(id);
    return index < 0 ? null : index + 1;
  }

  void _selectAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_visiblePhotos.map((photo) => photo.id));
      }
    });
  }

  void _toggleGroup(List<_GalleryPhoto> groupPhotos) {
    final allSelected = groupPhotos.isNotEmpty &&
        groupPhotos.every((photo) => _selectedIds.contains(photo.id));
    setState(() {
      if (allSelected) {
        _selectedIds.removeAll(groupPhotos.map((photo) => photo.id));
      } else {
        for (final photo in groupPhotos) {
          _selectedIds.add(photo.id);
        }
      }
    });
  }

  // ===========================================================================
  // LONG PRESS
  // ===========================================================================

  void _startSelection(
    _GalleryPhoto photo,
  ) {
    if (!_selectedIds.contains(
      photo.id,
    )) {
      _toggleSelection(
        photo.id,
      );
    }
  }

  // ===========================================================================
  // PHOTO TAP
  // ===========================================================================

  Future<void> _handlePhotoTap(
    _GalleryPhoto photo,
  ) async {
    // -------------------------------------------------------------------------
    // Selection mode
    // -------------------------------------------------------------------------

    if (_isSelecting) {
      _toggleSelection(
        photo.id,
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Open Photo Details
    // -------------------------------------------------------------------------

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoDetailsScreen(
          photo: photo.capturedPhoto,
          imageAsset: photo.imageAsset,
          locationLabel: photo.locationLabel,
          timestampLabel: '${photo.dateGroup} • '
              '${photo.timestampLabel}',
        ),
      ),
    );

    // -------------------------------------------------------------------------
    // Reload gallery after Photo Details delete
    // -------------------------------------------------------------------------

    if (mounted) {
      await _loadCapturedPhotos(showLoading: false);
    }
  }

  // ===========================================================================
  // INSTANT (OPTIMISTIC) LOCAL UPDATES
  // ===========================================================================

  _GalleryPhoto _withFavorite(_GalleryPhoto photo, bool favorite) {
    return _GalleryPhoto(
      id: photo.id,
      imageAsset: photo.imageAsset,
      imagePath: photo.imagePath,
      locationLabel: photo.locationLabel,
      timestampLabel: photo.timestampLabel,
      dateGroup: photo.dateGroup,
      capturedAt: photo.capturedAt,
      projectId: photo.projectId,
      projectName: photo.projectName,
      projectColorValue: photo.projectColorValue,
      isFavorite: favorite,
      capturedPhoto: photo.capturedPhoto?.copyWith(isFavorite: favorite),
    );
  }

  _GalleryPhoto _withProject(_GalleryPhoto photo, ProjectData project) {
    return _GalleryPhoto(
      id: photo.id,
      imageAsset: photo.imageAsset,
      imagePath: photo.imagePath,
      locationLabel: photo.locationLabel,
      timestampLabel: photo.timestampLabel,
      dateGroup: photo.dateGroup,
      capturedAt: photo.capturedAt,
      projectId: project.id,
      projectName: project.name,
      projectColorValue: project.colorValue,
      isFavorite: photo.isFavorite,
      capturedPhoto: photo.capturedPhoto?.copyWith(projectId: project.id),
    );
  }

  // ===========================================================================
  // SHARE SELECTED
  // ===========================================================================

  Future<void> _shareSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final files = _photos
        .where((photo) => _selectedIds.contains(photo.id))
        .map((photo) => photo.imagePath)
        .whereType<String>()
        .map(File.new)
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

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share ${AppBrand.name} photos',
          subject: '${AppBrand.name} photos',
          files: files,
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Unable to share photos: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Rect? _shareOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  bool get _allVisibleSelected {
    final visible = _visiblePhotos;
    return visible.isNotEmpty &&
        visible.every((photo) => _selectedIds.contains(photo.id));
  }

  Future<void> _moveSelectedToProject() async {
    if (_selectedIds.isEmpty) return;
    final repository = ProjectRepository.instance;
    await repository.ensureLoaded(refreshPhotos: true);
    if (!mounted) return;

    final project = await showModalBottomSheet<ProjectData>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final projects = repository.projects
            .where((item) => item.status == ProjectStatus.active)
            .toList();
        return SafeArea(
          child: projects.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: EmptyStatePlaceholder(
                    icon: Icons.folder_open_outlined,
                    title: 'No active projects',
                    description:
                        'Create a project from the Projects screen first.',
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
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

    // Show the change immediately: the photo leaves the Gallery and appears
    // in the Project views right away. Saving continues in the background.
    final ids = Set<String>.of(_selectedIds);
    setState(() {
      for (var i = 0; i < _photos.length; i++) {
        if (ids.contains(_photos[i].id)) {
          _photos[i] = _withProject(_photos[i], project);
        }
      }
      _selectedIds.clear();
    });

    try {
      final moved = await CapturedPhotoService.moveToProject(
        ids,
        projectId: project.id,
      );
      await repository.movePhotosToProject(project.id, moved);
      if (!mounted) return;
      await _loadCapturedPhotos(showLoading: false);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: moved.length == 1
            ? 'Photo moved to ${project.name}.'
            : '${moved.length} photos moved to ${project.name}.',
        icon: Icons.drive_file_move_outline,
      );
    } catch (error) {
      if (!mounted) return;
      await _loadCapturedPhotos(showLoading: false);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Unable to move photos: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _setSelectedFavorite() async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<String>.of(_selectedIds);
    final selectedPhotos =
        _photos.where((photo) => ids.contains(photo.id)).toList();
    final remove = selectedPhotos.isNotEmpty &&
        selectedPhotos.every((photo) => photo.isFavorite);
    final favorite = !remove;

    // Show the change immediately: the bookmark appears/disappears and the
    // photo is added to / removed from Favorites right away.
    setState(() {
      for (var i = 0; i < _photos.length; i++) {
        if (ids.contains(_photos[i].id)) {
          _photos[i] = _withFavorite(_photos[i], favorite);
        }
      }
      _selectedIds.clear();
    });

    try {
      await CapturedPhotoService.setFavorite(
        ids,
        favorite: favorite,
      );
    } catch (error) {
      if (!mounted) return;
      await _loadCapturedPhotos(showLoading: false);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Unable to update favorites: $error',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  // ===========================================================================
  // DELETE SELECTED
  // ===========================================================================

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final shouldDelete = await showDeleteConfirmationDialog(
      context,
      title: _selectedIds.length == 1
          ? 'Delete photo?'
          : 'Delete selected photos?',
      message: _selectedIds.length == 1
          ? 'This photo will be permanently removed from the app gallery.'
          : '${_selectedIds.length} photos will be permanently removed from '
              'the app gallery.',
    );

    if (!shouldDelete || !mounted) {
      return;
    }

    final deletedCount = _selectedIds.length;
    try {
      await CapturedPhotoService.deletePhotos(
        _selectedIds,
      );

      if (!mounted) return;

      _selectedIds.clear();

      await _loadCapturedPhotos();
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: deletedCount == 1
            ? 'Photo deleted successfully.'
            : '$deletedCount photos deleted successfully.',
        icon: Icons.delete_outline_rounded,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      debugPrint(
        'Gallery delete error: $e',
      );

      if (!mounted) return;

      AppTopToast.show(
        context,
        message: 'Unable to delete photo: $e',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  // ===========================================================================
  // MORE ACTIONS
  // ===========================================================================

  void _showMoreActions() {
    final selectedPhotos =
        _photos.where((photo) => _selectedIds.contains(photo.id)).toList();
    final removeFavorites = selectedPhotos.isNotEmpty &&
        selectedPhotos.every((photo) => photo.isFavorite);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.drive_file_move_outline,
                ),
                title: const Text(
                  'Move to project',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _moveSelectedToProject();
                },
              ),
              ListTile(
                leading: Icon(
                  removeFavorites ? Icons.bookmark : Icons.bookmark_border,
                  color: removeFavorites ? AppColors.primary : null,
                ),
                title: Text(
                  removeFavorites
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _setSelectedFavorite();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.select_all,
                ),
                title: Text(
                  _allVisibleSelected ? 'Deselect all' : 'Select all',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  _selectAllVisible();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FILTER (date wise / project name wise)
  // ===========================================================================

  void _setGroupMode(_GroupMode mode) {
    setState(() {
      _groupModes[_viewIndex] = mode;
      _selectedIds.clear();
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  'Filter by',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              RadioListTile<_GroupMode>(
                value: _GroupMode.date,
                groupValue: _groupMode,
                title: const Text('Date '),
                onChanged: (value) {
                  if (value == null) return;
                  Navigator.of(sheetContext).pop();
                  _setGroupMode(value);
                },
              ),
              RadioListTile<_GroupMode>(
                value: _GroupMode.project,
                groupValue: _groupMode,
                title: const Text('Project Name '),
                onChanged: (value) {
                  if (value == null) return;
                  Navigator.of(sheetContext).pop();
                  _setGroupMode(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterRow(double horizontalPadding) {
    final byProject = _groupMode == _GroupMode.project;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding - 8 < 0 ? 0 : horizontalPadding - 8,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              byProject ? 'Project name wise' : 'Date wise',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showFilterOptions,
            icon: const Icon(
              Icons.filter_list_rounded,
              size: 18,
            ),
            label: const Text('Filter'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB SELECTOR
  // ===========================================================================

  Widget _buildSegmentedTabs({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    double height = 44,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(
        4,
      ),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(
          AppRadius.md,
        ),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (
            index,
          ) {
            final selected = selectedIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < labels.length - 1 ? 4 : 0,
                ),
                child: Material(
                  color: selected
                      ? AppColors.isDarkMode
                          ? AppColors.primarySurface
                          : AppColors.lightSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppRadius.sm,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppRadius.sm,
                    ),
                    onTap: () => onSelected(index),
                    child: Center(
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // PROJECT STAMP HELPERS
  // ===========================================================================

  /// First letter of the first two words ("Alpha Beta" -> "AB").
  /// A one word name uses its first two letters ("Metro" -> "ME").
  String _projectInitials(String? name) {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '?';

    String firstChars(String word, int count) =>
        String.fromCharCodes(word.runes.take(count));

    if (words.length == 1) {
      return firstChars(words.first, 2).toUpperCase();
    }

    return '${firstChars(words[0], 1)}${firstChars(words[1], 1)}'
        .toUpperCase();
  }

  /// Black text on light/white project colours, white text otherwise.
  Color _onColor(Color background) {
    return background.computeLuminance() > 0.6 ? Colors.black : Colors.white;
  }

  Widget _buildStampChip({
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ===========================================================================
  // GROUP HEADER (date / project name)
  // ===========================================================================

  Widget _buildGroupHeader(
    _PhotoGroup group,
    double horizontalPadding,
  ) {
    return InkWell(
      onTap: _isSelecting ? () => _toggleGroup(group.photos) : null,
      onLongPress: () => _toggleGroup(group.photos),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GROUPED LIST (date / project headers + photo grids)
  // ===========================================================================

  Widget _buildGroupedList(
    List<_GalleryPhoto> photos,
    int columns,
    double horizontalPadding,
  ) {
    final groups = _buildGroups(photos);

    return CustomScrollView(
      slivers: [
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: _buildGroupHeader(group, horizontalPadding),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              6,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                // Keep every photo tile square.
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPhotoCard(group.photos[index]),
                childCount: group.photos.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  // ===========================================================================
  // PHOTO CARD
  // ===========================================================================

  Widget _buildPhotoCard(
    _GalleryPhoto photo,
  ) {
    final selected = _selectedIds.contains(
      photo.id,
    );
    final selectionNumber = _selectionNumber(photo.id);

    final byProject = _isRoot && _groupMode == _GroupMode.project;

    // Time / date stamps: white text on a translucent black background.
    final stampBackground = Colors.black.withValues(alpha: 0.6);
    const stampForeground = Colors.white;

    // The project cover image is shown in the round badge when available.
    // Keep the existing initials-and-colour fallback for projects without
    // a valid custom cover image.
    final badgeBackground = Color(photo.projectColorValue ?? 0xFF6D28D9);
    final badgeForeground = _onColor(badgeBackground);
    final badgeProject = photo.projectId == null
        ? null
        : ProjectRepository.instance.findById(photo.projectId!);
    final badgeCoverPath = badgeProject?.coverImagePath;
    final hasBadgeCover = badgeCoverPath != null &&
        badgeCoverPath.isNotEmpty &&
        !isGeneratedProjectNameCover(badgeCoverPath) &&
        File(badgeCoverPath).existsSync();

    // Project badge: both Project and Favorites > Project views, date wise.
    final showProjectBadge =
        _isRoot && _isProjectView && !byProject && photo.projectId != null;

    Widget buildProjectInitialsBadge() => Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            _projectInitials(photo.projectName),
            maxLines: 1,
            style: TextStyle(
              color: badgeForeground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    return Material(
      key: ValueKey<String>(photo.id),
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        AppRadius.md,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handlePhotoTap(
          photo,
        ),
        onLongPress: () => _startSelection(
          photo,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===============================================================
            // PHOTO
            // ===============================================================

            if (photo.imagePath != null)
              Image.file(
                File(
                  photo.imagePath!,
                ),
                fit: BoxFit.cover,
                errorBuilder: _imageError,
              )
            else if (photo.imageAsset != null)
              Image.asset(
                photo.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: _imageError,
              )
            else
              _imageError(
                context,
                'No image',
                null,
              ),

            // ===============================================================
            // BOOKMARK (favorite)
            // ===============================================================

            if (photo.isFavorite && selectionNumber == null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // ===============================================================
            // DATE STAMP (project name wise lists)
            // ===============================================================

            if (byProject)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  color: stampBackground,
                  child: Text(
                    photo.dateGroup,
                    maxLines: 1,
                    style: TextStyle(
                      color: stampForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // ===============================================================
            // PROJECT NAME STAMP (initials badge)
            // ===============================================================

            if (showProjectBadge)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasBadgeCover
                      ? Image.file(
                          File(badgeCoverPath!),
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              buildProjectInitialsBadge(),
                        )
                      : buildProjectInitialsBadge(),
                ),
              ),

            // ===============================================================
            // TIME STAMP (top right)
            // ===============================================================

            Positioned(
              top: 8,
              right: 8,
              child: _buildStampChip(
                text: photo.timestampLabel,
                background: stampBackground,
                foreground: stampForeground,
              ),
            ),

            // ===============================================================
            // SELECTED OVERLAY
            // ===============================================================

            if (selected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppRadius.md,
                      ),
                    ),
                  ),
                ),
              ),
            if (selectionNumber != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$selectionNumber',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
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

  // ===========================================================================
  // IMAGE ERROR
  // ===========================================================================

  Widget _imageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: const Color(
        0xFFEEF2F7,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 38,
        color: Color(
          0xFF94A3B8,
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTION BAR
  // ===========================================================================

  Widget _buildSelectionBar(
    double horizontalPadding,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        6,
        horizontalPadding,
        6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedIds.length} selected',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _shareSelected,
            icon: const Icon(
              Icons.ios_share_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteSelected,
            color: AppColors.error,
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreActions,
            icon: const Icon(
              Icons.more_horiz,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final visiblePhotos = _visiblePhotos;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // -----------------------------------------------------------------------
      // TOP BAR
      // -----------------------------------------------------------------------

      appBar: AppTopBar(
        title: widget.title ?? 'Gallery',
        showBack: !_isRoot,
        showConnectivityStatus: _isRoot,
        actions: [
          if (visiblePhotos.length > 1)
            IconButton(
              tooltip:
                  _allVisibleSelected ? 'Clear selection' : 'Multiple select',
              onPressed: _selectAllVisible,
              icon: Icon(
                _allVisibleSelected
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
              ),
            ),
        ],
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width = constraints.maxWidth;

            final isTablet = width >= 600;

            // Phones: 1 row = 2 images.
            final columns = width >= 1000
                ? 5
                : isTablet
                    ? 4
                    : 2;

            final horizontalPadding =
                isTablet ? 32.0 : AppSpacing.screenPadding;

            if (_loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Column(
                  children: [
                    // =========================================================
                    // MAIN TABS: Gallery | Project | Favorites
                    // =========================================================

                    if (_isRoot)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.sm,
                          horizontalPadding,
                          AppSpacing.sm,
                        ),
                        child: _buildSegmentedTabs(
                          labels: _mainTabs,
                          selectedIndex: _tabIndex,
                          onSelected: (index) {
                            setState(() {
                              _tabIndex = index;
                              _selectedIds.clear();
                            });
                          },
                        ),
                      ),

                    // =========================================================
                    // FAVORITES SUB TABS: Gallery | Project
                    // =========================================================

                    if (_isRoot && _tabIndex == 2)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          AppSpacing.sm,
                        ),
                        child: _buildSegmentedTabs(
                          labels: _favoriteTabs,
                          selectedIndex: _favoriteTabIndex,
                          height: 40,
                          onSelected: (index) {
                            setState(() {
                              _favoriteTabIndex = index;
                              _selectedIds.clear();
                            });
                          },
                        ),
                      ),

                    // =========================================================
                    // FILTER (date wise / project name wise)
                    // =========================================================

                    if (_isRoot && _isProjectView)
                      _buildFilterRow(horizontalPadding),

                    // =========================================================
                    // GALLERY
                    // =========================================================

                    Expanded(
                      child: visiblePhotos.isEmpty
                          ? EmptyStatePlaceholder(
                              icon: _isRoot && _tabIndex == 2
                                  ? Icons.bookmark_border_rounded
                                  : Icons.photo_library_outlined,
                              title: _isRoot && _tabIndex == 2
                                  ? 'No favorites yet'
                                  : _isRoot && _tabIndex == 1
                                      ? 'No project photos'
                                      : 'No photos found',
                              description: _isRoot && _tabIndex == 2
                                  ? 'Bookmarked photos will appear here.'
                                  : _isRoot && _tabIndex == 1
                                      ? 'Photos added to a project will '
                                          'appear here.'
                                      : 'Photos that are not in a project '
                                          'will appear here.',
                            )
                          : _isRoot
                              ? _buildGroupedList(
                                  visiblePhotos,
                                  columns,
                                  horizontalPadding,
                                )
                              : GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    10,
                                    horizontalPadding,
                                    20,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    // Keep every photo tile square on phones and tablets.
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: visiblePhotos.length,
                                  itemBuilder: (context, index) =>
                                      _buildPhotoCard(visiblePhotos[index]),
                                ),
                    ),

                    // =========================================================
                    // MULTI SELECT ACTION BAR
                    // =========================================================

                    if (_isSelecting)
                      _buildSelectionBar(
                        horizontalPadding,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // -----------------------------------------------------------------------
      // BOTTOM NAVIGATION
      // -----------------------------------------------------------------------

      bottomNavigationBar: _isRoot
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdBannerWidget(
                  format: AdDisplayFormat.largeBanner,
                  reserveSpaceWhileLoading: true,
                ),
                AppBottomNavBar(
                  currentIndex: 1,
                  onTap: (index) =>
                      AppNavigator.handleBottomNavTap(context, index),
                ),
              ],
            )
          : null,
    );
  }
}