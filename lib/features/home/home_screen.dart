import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../camera/live_camera_screen.dart';
import '../gallery/photo_details_screen.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/services/notification_repository.dart';
import '../projects/project_data.dart';
import '../projects/project_details_screen.dart';
import '../projects/recent_projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.currentNavIndex = 0,
    this.onNavTap,
    this.onViewAllCaptures,
    this.onCaptureTap,
    this.onViewAllProjects,
    this.onRecentProjectTap,
  });

  final int currentNavIndex;
  final ValueChanged<int>? onNavTap;
  final VoidCallback? onViewAllCaptures;

  /// Now uses the real saved photo model.
  final ValueChanged<CapturedPhoto>? onCaptureTap;

  final VoidCallback? onViewAllProjects;
  final VoidCallback? onRecentProjectTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===========================================================================
  // REAL RECENT CAPTURES
  // ===========================================================================

  List<CapturedPhoto> _recentCaptures = <CapturedPhoto>[];

  bool _isLoadingCaptures = true;

  // ===========================================================================
  // RECENT PROJECT
  // ===========================================================================

  final ProjectRepository _projectRepository = ProjectRepository.instance;
  final NotificationRepository _notificationRepository =
      NotificationRepository.instance;
  List<ProjectData> _recentProjects = <ProjectData>[];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _projectRepository.addListener(_refreshProject);
    _notificationRepository.addListener(_refreshNotifications);
    _notificationRepository.ensureLoaded();
    _loadRecentCaptures();
  }

  void _refreshProject() {
    if (!mounted) return;
    setState(() {
      _recentProjects = _projectRepository.projects;
    });
  }

  void _refreshNotifications() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _projectRepository.removeListener(_refreshProject);
    _notificationRepository.removeListener(_refreshNotifications);
    super.dispose();
  }

  // ===========================================================================
  // LOAD REAL SAVED PHOTOS
  // ===========================================================================

  Future<void> _loadRecentCaptures() async {
    try {
      final photos = await CapturedPhotoService.loadPhotos();
      await _projectRepository.ensureLoaded(refreshPhotos: true);

      if (!mounted) {
        return;
      }

      setState(() {
        // CapturedPhotoService stores newest photo first.
        //
        // Only show latest 5 photos on Home Screen.
        _recentCaptures = photos.take(5).toList();
        _recentProjects = _projectRepository.projects;
        _isLoadingCaptures = false;
      });
    } catch (e) {
      debugPrint(
        'Home recent capture loading error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recentCaptures = <CapturedPhoto>[];
        _isLoadingCaptures = false;
      });
    }
  }

  // ===========================================================================
  // OPEN CAMERA
  // ===========================================================================

  Future<void> _openCamera(
    BuildContext context,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LiveCameraScreen(),
      ),
    );

    // -------------------------------------------------------------------------
    // Camera/preview closed.
    //
    // Reload SharedPreferences so the newly saved photo immediately appears
    // under Recent Captures.
    // -------------------------------------------------------------------------

    await _loadRecentCaptures();
  }

  // ===========================================================================
  // BOTTOM NAVIGATION
  // ===========================================================================

  void _handleNavTap(
    BuildContext context,
    int index,
  ) {
    // -------------------------------------------------------------------------
    // Camera button
    // -------------------------------------------------------------------------

    if (index == 2) {
      _openCamera(context);
      return;
    }

    if (widget.onNavTap != null) {
      widget.onNavTap!(index);
      return;
    }

    AppNavigator.handleBottomNavTap(
      context,
      index,
    );
  }

  // ===========================================================================
  // VIEW ALL CAPTURES
  // ===========================================================================

  void _handleViewAllCaptures(
    BuildContext context,
  ) {
    if (widget.onViewAllCaptures != null) {
      widget.onViewAllCaptures!();
      return;
    }

    AppNavigator.goToGallery(context);
  }

  // ===========================================================================
  // OPEN CAPTURE
  // ===========================================================================

  void _handleCaptureTap(
    BuildContext context,
    CapturedPhoto capture,
  ) {
    if (widget.onCaptureTap != null) {
      widget.onCaptureTap!(capture);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoDetailsScreen(photo: capture),
      ),
    );
  }

  // ===========================================================================
  // PROJECTS
  // ===========================================================================

  void _handleViewAllProjects(
    BuildContext context,
  ) {
    if (widget.onViewAllProjects != null) {
      widget.onViewAllProjects!();
      return;
    }

    AppNavigator.goToProjects(context);
  }

  void _handleViewAllRecentProjects(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RecentProjectsScreen(),
      ),
    );
  }

  void _handleRecentProjectTap(
    BuildContext context,
    ProjectData project,
  ) {
    if (widget.onRecentProjectTap != null) {
      widget.onRecentProjectTap!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
  }

  // ===========================================================================
  // PROJECT IMAGE
  // ===========================================================================

  ImageProvider _resolveImage(
    String assetPath,
  ) {
    return AssetImage(
      assetPath,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // =======================================================================
      // APP BAR
      // =======================================================================

      appBar: AppTopBar(
        title: 'Home',
        showBack: false,
        showConnectivityStatus: true,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (_notificationRepository.unreadCount > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _notificationRepository.unreadCount > 9
                            ? '9+'
                            : '${_notificationRepository.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),

      // =======================================================================
      // BODY
      // =======================================================================

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final isWide =
                constraints.maxWidth >= 600;

            final maxContentWidth =
                isWide ? 720.0 : double.infinity;

            final captureThumbSize =
                isWide ? 150.0 : 126.0;

            final horizontalPadding =
                isWide
                    ? 32.0
                    : AppSpacing.screenPadding;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: _loadRecentCaptures,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.screenPadding,
                      horizontalPadding,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // =======================================================
                      // RECENT CAPTURES HEADER
                      // =======================================================

                      _SectionHeader(
                        title: 'Recent Captures',
                        onViewAll: _recentCaptures.length > 3
                            ? () {
                                _handleViewAllCaptures(
                                  context,
                                );
                              }
                            : null,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      // =======================================================
                      // LOADING
                      // =======================================================

                      if (_isLoadingCaptures)
                        const SizedBox(
                          height: 170,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )

                      // =======================================================
                      // EMPTY
                      // =======================================================

                      else if (_recentCaptures.isEmpty)
                        EmptyStatePlaceholder(
                          icon: Icons.photo_camera_outlined,
                          title: 'No captures yet',
                          titleColor: AppColors.textSecondary,
                          description:
                              'Photos you take will show up here.',
                        )

                      // =======================================================
                      // REAL RECENT PHOTOS
                      // =======================================================

                      else
                        SizedBox(
                          height: captureThumbSize,
                          child: ListView.separated(
                            scrollDirection:
                                Axis.horizontal,
                            itemCount:
                                _recentCaptures.length,
                            separatorBuilder: (
                              _,
                              __,
                            ) {
                              return const SizedBox(
                                width: AppSpacing.md,
                              );
                            },
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final capture =
                                  _recentCaptures[index];

                              return SizedBox(
                                width: captureThumbSize,
                                child:
                                    PhotoThumbnailCard(
                                  // ===========================================
                                  // REAL SAVED PHOTO
                                  // ===========================================

                                  imageProvider:
                                      FileImage(
                                    File(
                                      capture.path,
                                    ),
                                  ),

                                  onTap: () {
                                    _handleCaptureTap(
                                      context,
                                      capture,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // Full-width banner between recent photos and projects.
                      const SizedBox(
                        width: double.infinity,
                        child: AdBannerWidget(
                          format: AdDisplayFormat.adaptiveBanner,
                          reserveSpaceWhileLoading: true,
                          slotHeight: 80,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // =======================================================
                      // PROJECTS
                      // =======================================================

                      _SectionHeader(
                        title: 'Recent Projects',
                        onViewAll: _recentProjects.length > 3
                            ? () => _handleViewAllRecentProjects(context)
                            : null,
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      if (_recentProjects.isNotEmpty)
                        ..._recentProjects.take(3).map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: ProjectCard(
                              name: project.name,
                              location: project.location,
                              photoCount: project.photoCount,
                              coverColor: Color(project.colorValue),
                              updatedLabel: 'Today',
                              imageProvider: project.coverImagePath != null &&
                                      !isGeneratedProjectNameCover(project.coverImagePath) &&
                                      File(project.coverImagePath!).existsSync()
                                  ? FileImage(File(project.coverImagePath!))
                                  : null,
                              showChevron: true,
                              onTap: () =>
                                  _handleRecentProjectTap(context, project),
                            ),
                          ),
                        )
                      else
                        EmptyStatePlaceholder(
                          icon: Icons.folder_open_outlined,
                          title: 'No recent projects',
                          titleColor: AppColors.textSecondary,
                          description:
                              'Projects created or with photos added or moved today will show up here.',
                        ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // =======================================================================
      // BOTTOM NAV
      // =======================================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomNavBar(
            currentIndex: widget.currentNavIndex,
            onTap: (index) {
              _handleNavTap(context, index);
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View all',
              style:
                  AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
