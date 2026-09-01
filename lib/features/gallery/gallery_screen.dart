import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'photo_details_screen.dart';
import '../projects/project_data.dart';

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
    this.projectName,
    this.isFavorite = false,
    this.capturedPhoto,
  });

  final String id;

  final String? imageAsset;
  final String? imagePath;

  final String locationLabel;
  final String timestampLabel;
  final String dateGroup;

  final String? projectName;

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
  });

  @override
  State<GalleryScreen> createState() =>
      _GalleryScreenState();
}

class _GalleryScreenState
    extends State<GalleryScreen> {
  static const List<String> _tabs = [
    'All',
    'Projects',
    'Favorites',
  ];

  final TextEditingController
      _searchController =
      TextEditingController();

  final Set<String> _selectedIds =
      <String>{};

  final List<_GalleryPhoto> _photos =
      <_GalleryPhoto>[];

  int _tabIndex = 0;

  bool _showSearch = false;

  bool _loading = true;

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
    _searchController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // LOAD REAL CAPTURED PHOTOS
  // ===========================================================================

  Future<void> _loadCapturedPhotos() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      await ProjectRepository.instance.ensureLoaded(refreshPhotos: true);

      final capturedPhotos =
          await CapturedPhotoService
              .loadPhotos();

      debugPrint(
        'Gallery captured photo count: '
        '${capturedPhotos.length}',
      );

      for (final photo
          in capturedPhotos) {
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

        _photos.addAll(
          capturedPhotos.map(
            (photo) =>
                _GalleryPhoto(
              id: photo.id,

              imagePath:
                  photo.path,

              locationLabel:
                  photo.location,

              timestampLabel:
                  _timeLabel(
                photo.capturedAt,
              ),

              dateGroup:
                  _dateLabel(
                photo.capturedAt,
              ),

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
              capturedPhoto:
                  photo,
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
    final hour =
        value.hour % 12 == 0
            ? 12
            : value.hour % 12;

    final minute =
        value.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        value.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

  String _dateLabel(
    DateTime value,
  ) {
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

    return '${value.day} '
        '${months[value.month - 1]} '
        '${value.year}';
  }

  // ===========================================================================
  // SELECTION STATE
  // ===========================================================================

  bool get _isSelecting =>
      _selectedIds.isNotEmpty;

  // ===========================================================================
  // FILTERED PHOTOS
  // ===========================================================================

  List<_GalleryPhoto>
      get _visiblePhotos {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return _photos.where(
      (photo) {
        final bool matchesTab;

        switch (_tabIndex) {
          case 1:
            matchesTab =
                photo.projectName !=
                    null;
            break;

          case 2:
            matchesTab =
                photo.isFavorite;
            break;

          default:
            matchesTab = true;
        }

        final matchesSearch =
            query.isEmpty ||
                photo
                    .locationLabel
                    .toLowerCase()
                    .contains(
                      query,
                    ) ||
                photo
                    .dateGroup
                    .toLowerCase()
                    .contains(
                      query,
                    ) ||
                (photo.projectName
                        ?.toLowerCase()
                        .contains(
                          query,
                        ) ??
                    false);

        return matchesTab &&
            matchesSearch;
      },
    ).toList();
  }

  // ===========================================================================
  // DATE GROUPS
  // ===========================================================================

  List<String>
      get _visibleDateGroups {
    final groups =
        <String>[];

    for (final photo
        in _visiblePhotos) {
      if (!groups.contains(
        photo.dateGroup,
      )) {
        groups.add(
          photo.dateGroup,
        );
      }
    }

    return groups;
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

    final wasDeleted =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PhotoDetailsScreen(
          photo:
              photo.capturedPhoto,

          imageAsset:
              photo.imageAsset,

          locationLabel:
              photo.locationLabel,

          timestampLabel:
              '${photo.dateGroup} • '
              '${photo.timestampLabel}',
        ),
      ),
    );

    // -------------------------------------------------------------------------
    // Reload gallery after Photo Details delete
    // -------------------------------------------------------------------------

    if (wasDeleted == true &&
        mounted) {
      await _loadCapturedPhotos();
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected photo files are unavailable.')),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share GPS Camera photos',
          subject: 'GPS Camera photos',
          files: files,
          sharePositionOrigin: _shareOrigin(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share photos: $error')),
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
                    description: 'Create a project from the Projects screen first.',
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
                        leading: Icon(Icons.folder_outlined, color: item.color),
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
    try {
      final moved = await CapturedPhotoService.moveToProject(
        _selectedIds,
        projectId: project.id,
      );
      await repository.movePhotosToProject(project.id, moved);
      if (!mounted) return;
      _selectedIds.clear();
      await _loadCapturedPhotos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photos moved to ${project.name}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to move photos: $error')),
      );
    }
  }

  Future<void> _setSelectedFavorite() async {
    if (_selectedIds.isEmpty) return;
    final selectedPhotos =
        _photos.where((photo) => _selectedIds.contains(photo.id)).toList();
    final remove = selectedPhotos.isNotEmpty &&
        selectedPhotos.every((photo) => photo.isFavorite);
    try {
      await CapturedPhotoService.setFavorite(
        _selectedIds,
        favorite: !remove,
      );
      if (!mounted) return;
      _selectedIds.clear();
      await _loadCapturedPhotos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update favorites: $error')),
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

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: Text(
            _selectedIds.length == 1
                ? 'Delete photo?'
                : 'Delete selected photos?',
          ),
          content: Text(
            _selectedIds.length == 1
                ? 'This photo will be permanently removed from the app gallery.'
                : '${_selectedIds.length} photos will be permanently removed from the app gallery.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              child:
                  const Text(
                'Delete',
                style:
                    TextStyle(
                  color:
                      AppColors
                          .error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    try {
      await CapturedPhotoService
          .deletePhotos(
        _selectedIds,
      );

      if (!mounted) return;

      _selectedIds.clear();

      await _loadCapturedPhotos();
    } catch (e) {
      debugPrint(
        'Gallery delete error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete photo: $e',
          ),
        ),
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
      builder:
          (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .drive_file_move_outline,
                ),
                title:
                    const Text(
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
                  removeFavorites ? Icons.favorite : Icons.favorite_border,
                  color: removeFavorites ? AppColors.error : null,
                ),
                title:
                    Text(
                  removeFavorites ? 'Remove from favorites' : 'Add to favorites',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();
                  _setSelectedFavorite();
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.select_all,
                ),
                title:
                    Text(
                  _allVisibleSelected ? 'Deselect all' : 'Select all',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  setState(() {
                    if (_allVisibleSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(_visiblePhotos.map((photo) => photo.id));
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  void _showFilterOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title:
                    Text(
                  'Filter gallery',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),

              for (var index = 0;
                  index <
                      _tabs.length;
                  index++)
                RadioListTile<int>(
                  value:
                      index,
                  groupValue:
                      _tabIndex,
                  title:
                      Text(
                    _tabs[
                        index],
                  ),
                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    Navigator.of(
                      sheetContext,
                    ).pop();

                    setState(() {
                      _tabIndex =
                          value;

                      _selectedIds
                          .clear();
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB SELECTOR
  // ===========================================================================

  Widget _buildTabs() {
    return Container(
      height: 44,
      padding:
          const EdgeInsets.all(
        4,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF1F5F9,
        ),
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),
      ),
      child:
          Row(
        children:
            List.generate(
          _tabs.length,
          (
            index,
          ) {
            final selected =
                _tabIndex ==
                    index;

            return Expanded(
              child:
                  Padding(
                padding:
                    EdgeInsets.only(
                  right:
                      index <
                              _tabs.length -
                                  1
                          ? 4
                          : 0,
                ),
                child:
                    Material(
                  color:
                      selected
                          ? AppColors
                              .white
                          : Colors
                              .transparent,
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.sm,
                  ),
                  child:
                      InkWell(
                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.sm,
                    ),
                    onTap:
                        () {
                      setState(
                        () {
                          _tabIndex =
                              index;

                          _selectedIds
                              .clear();
                        },
                      );
                    },
                    child:
                        Center(
                      child:
                          Text(
                        _tabs[
                            index],
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            AppTypography.caption.copyWith(
                          color:
                              selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          fontWeight:
                              selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
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
  // PHOTO CARD
  // ===========================================================================

  Widget _buildPhotoCard(
    _GalleryPhoto photo,
  ) {
    final selected =
        _selectedIds.contains(
      photo.id,
    );

    return Material(
      color:
          AppColors.white,
      borderRadius:
          BorderRadius.circular(
        AppRadius.md,
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          InkWell(
        onTap:
            () =>
                _handlePhotoTap(
          photo,
        ),
        onLongPress:
            () =>
                _startSelection(
          photo,
        ),
        child:
            Stack(
          fit:
              StackFit.expand,
          children: [
            // ===============================================================
            // PHOTO
            // ===============================================================

            if (photo.imagePath !=
                null)
              Image.file(
                File(
                  photo
                      .imagePath!,
                ),
                fit:
                    BoxFit.cover,
                errorBuilder:
                    _imageError,
              )
            else if (photo.imageAsset !=
                null)
              Image.asset(
                photo
                    .imageAsset!,
                fit:
                    BoxFit.cover,
                errorBuilder:
                    _imageError,
              )
            else
              _imageError(
                context,
                'No image',
                null,
              ),

            // ===============================================================
            // BOTTOM GRADIENT
            // ===============================================================

            const Positioned.fill(
              child:
                  DecoratedBox(
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment
                            .topCenter,
                    end:
                        Alignment
                            .bottomCenter,
                    colors: [
                      Colors
                          .transparent,
                      Colors
                          .transparent,
                      Color(
                        0xDD000000,
                      ),
                    ],
                    stops: [
                      0,
                      0.52,
                      1,
                    ],
                  ),
                ),
              ),
            ),

            // ===============================================================
            // LOCATION + TIME
            // ===============================================================

            Positioned(
              left:
                  10,
              right:
                  34,
              bottom:
                  9,
              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    photo
                        .locationLabel,
                    maxLines:
                        1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height:
                        2,
                  ),

                  Text(
                    photo
                        .timestampLabel,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ===============================================================
            // ARROW
            // ===============================================================

            const Positioned(
              right:
                  8,
              bottom:
                  12,
              child:
                  Icon(
                Icons
                    .chevron_right,
                color:
                    Colors.white,
                size:
                    20,
              ),
            ),

            if (photo.isFavorite)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.error,
                    size: 19,
                  ),
                ),
              ),

            // ===============================================================
            // SELECTED OVERLAY
            // ===============================================================

            if (selected)
              Positioned.fill(
                child:
                    IgnorePointer(
                  child:
                      DecoratedBox(
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primary.withValues(
                        alpha:
                            0.12,
                      ),
                      border:
                          Border.all(
                        color:
                            AppColors.primary,
                        width:
                            3,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.md,
                      ),
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
      color:
          const Color(
        0xFFEEF2F7,
      ),
      alignment:
          Alignment.center,
      child:
          const Icon(
        Icons.image_outlined,
        size:
            38,
        color:
            Color(
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
      padding:
          EdgeInsets.fromLTRB(
        horizontalPadding,
        6,
        horizontalPadding,
        6,
      ),
      decoration:
          const BoxDecoration(
        color:
            AppColors.white,
        border:
            Border(
          top:
              BorderSide(
            color:
                AppColors.border,
          ),
        ),
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              '${_selectedIds.length} selected',
              style:
                  AppTypography.bodyMedium.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          IconButton(
            tooltip:
                'Share',
            onPressed:
                _shareSelected,
            icon:
                const Icon(
              Icons
                  .ios_share_outlined,
            ),
          ),

          IconButton(
            tooltip:
                'Delete',
            onPressed:
                _deleteSelected,
            color:
                AppColors.error,
            icon:
                const Icon(
              Icons
                  .delete_outline,
            ),
          ),

          IconButton(
            tooltip:
                'More',
            onPressed:
                _showMoreActions,
            icon:
                const Icon(
              Icons
                  .more_horiz,
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
    final visiblePhotos =
        _visiblePhotos;

    return Scaffold(
      backgroundColor:
          AppColors.background,

      // -----------------------------------------------------------------------
      // TOP BAR
      // -----------------------------------------------------------------------

      appBar:
          AppTopBar(
        title:
            'Gallery',
        showBack:
            false,
        actions: [
          IconButton(
            onPressed:
                () {
              setState(() {
                _showSearch =
                    !_showSearch;

                if (!_showSearch) {
                  _searchController
                      .clear();
                }
              });
            },
            icon:
                Icon(
              _showSearch
                  ? Icons.close
                  : Icons.search,
            ),
          ),

        ],
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body:
          SafeArea(
        top:
            false,
        child:
            LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final isTablet =
                width >=
                    600;

            final columns =
                width >=
                        1000
                    ? 5
                    : isTablet
                        ? 4
                        : 2;

            final horizontalPadding =
                isTablet
                    ? 32.0
                    : AppSpacing
                        .screenPadding;

            if (_loading) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            return Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      1100,
                ),
                child:
                    Column(
                  children: [
                    // =========================================================
                    // SEARCH
                    // =========================================================

                    if (_showSearch)
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          0,
                        ),
                        child:
                            TextField(
                          controller:
                              _searchController,
                          autofocus:
                              true,
                          onChanged:
                              (_) {
                            setState(
                              () {},
                            );
                          },
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search location, project or date',
                            prefixIcon:
                                const Icon(
                              Icons.search,
                            ),
                            filled:
                                true,
                            fillColor:
                                AppColors.white,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                AppRadius.md,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                    // =========================================================
                    // TABS
                    //
                    // Local implementation fixes the Expanded/Padding crash.
                    // =========================================================

                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AppSpacing.sm,
                        horizontalPadding,
                        AppSpacing.sm,
                      ),
                      child:
                          _buildTabs(),
                    ),

                    // =========================================================
                    // GALLERY
                    // =========================================================

                    Expanded(
                      child:
                          visiblePhotos.isEmpty
                              ? const EmptyStatePlaceholder(
                                  icon:
                                      Icons.photo_library_outlined,
                                  title:
                                      'No photos found',
                                  description:
                                      'Captured photos will appear here.',
                                )
                              : ListView(
                                  padding:
                                      EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    0,
                                    horizontalPadding,
                                    20,
                                  ),
                                  children: [
                                    for (final group
                                        in _visibleDateGroups) ...[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top:
                                              10,
                                          bottom:
                                              10,
                                        ),
                                        child:
                                            Text(
                                          group,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                      ),

                                      Builder(
                                        builder:
                                            (
                                          context,
                                        ) {
                                          final groupPhotos =
                                              visiblePhotos
                                                  .where(
                                                    (
                                                      photo,
                                                    ) =>
                                                        photo.dateGroup ==
                                                        group,
                                                  )
                                                  .toList();

                                          return GridView.builder(
                                            shrinkWrap:
                                                true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  columns,
                                              mainAxisSpacing:
                                                  10,
                                              crossAxisSpacing:
                                                  10,
                                              childAspectRatio:
                                                  isTablet
                                                      ? 1.25
                                                      : 1.18,
                                            ),
                                            itemCount:
                                                groupPhotos.length,
                                            itemBuilder:
                                                (
                                              context,
                                              index,
                                            ) {
                                              return _buildPhotoCard(
                                                groupPhotos[
                                                    index],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
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

      bottomNavigationBar:
          AppBottomNavBar(
        currentIndex:
            1,
        onTap:
            (index) =>
                AppNavigator.handleBottomNavTap(
          context,
          index,
        ),
      ),
    );
  }
}
