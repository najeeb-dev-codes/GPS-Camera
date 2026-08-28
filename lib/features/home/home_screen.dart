
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
  // PROJECT MOCK DATA
  // ===========================================================================

  static const String _recentProjectName = 'Highway Project';

  static const String _recentProjectImageAsset =
      'assets/images/projects/highway_project.jpg';

  static const int _recentProjectPhotoCount = 68;

  static const String _recentProjectUpdatedLabel = 'Updated today';

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadRecentCaptures();
  }

  // ===========================================================================
  // LOAD REAL SAVED PHOTOS
  // ===========================================================================

  Future<void> _loadRecentCaptures() async {
    try {
      final photos = await CapturedPhotoService.loadPhotos();

      if (!mounted) {
        return;
      }

      setState(() {
        // CapturedPhotoService stores newest photo first.
        //
        // Only show latest 5 photos on Home Screen.
        _recentCaptures = photos.take(5).toList();

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
  // COMING SOON
  // ===========================================================================

  void _showComingSoon(
    BuildContext context, {
    required String featureName,
    required IconData icon,
  }) {
    ComingSoonDialog.show(
      context,
      featureName: featureName,
      icon: icon,
    );
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

  void _handleRecentProjectTap(
    BuildContext context,
  ) {
    if (widget.onRecentProjectTap != null) {
      widget.onRecentProjectTap!();
      return;
    }

    AppNavigator.goToProjects(context);
  }

  // ===========================================================================
  // FORMAT DATE / TIME
  // ===========================================================================

  String _formatCapturedTime(
    DateTime value,
  ) {
    final day = value.day.toString().padLeft(
          2,
          '0',
        );

    final month = value.month.toString().padLeft(
          2,
          '0',
        );

    final hour = value.hour % 12 == 0
        ? 12
        : value.hour % 12;

    final minute = value.minute.toString().padLeft(
          2,
          '0',
        );

    final period = value.hour >= 12
        ? 'PM'
        : 'AM';

    return '$day/$month/${value.year} - '
        '$hour:$minute $period';
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
      backgroundColor: AppColors.background,

      // =======================================================================
      // APP BAR
      // =======================================================================

      appBar: AppTopBar(
        title: 'Home',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
            onPressed: () {
              _showComingSoon(
                context,
                featureName: 'Notifications',
                icon: Icons.notifications_none_rounded,
              );
            },
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
                isWide ? 170.0 : 145.0;

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
                        onViewAll: () {
                          _handleViewAllCaptures(
                            context,
                          );
                        },
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
                        const EmptyStatePlaceholder(
                          icon: Icons.photo_camera_outlined,
                          title: 'No captures yet',
                          description:
                              'Photos you take will show up here.',
                        )

                      // =======================================================
                      // REAL RECENT PHOTOS
                      // =======================================================

                      else
                        SizedBox(
                          height: captureThumbSize + 88,
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
                                width:
                                    captureThumbSize + 10,
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

                                  // ===========================================
                                  // TITLE
                                  // ===========================================

                                  titleLabel:
                                      'GPS Capture',

                                  // ===========================================
                                  // REAL LOCATION
                                  // ===========================================

                                  locationLabel:
                                      capture.location,

                                  // ===========================================
                                  // REAL CAPTURE TIME
                                  // ===========================================

                                  timestampLabel:
                                      _formatCapturedTime(
                                    capture.capturedAt,
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

                      const SizedBox(
                        height: AppSpacing.xxl,
                      ),

                      // =======================================================
                      // PROJECTS
                      // =======================================================

                      _SectionHeader(
                        title: 'Projects',
                        onViewAll: () {
                          _handleViewAllProjects(
                            context,
                          );
                        },
                      ),

                      const SizedBox(
                        height: AppSpacing.md,
                      ),

                      ProjectCard(
                        name:
                            _recentProjectName,
                        photoCount:
                            _recentProjectPhotoCount,
                        updatedLabel:
                            _recentProjectUpdatedLabel,
                        imageProvider:
                            _resolveImage(
                          _recentProjectImageAsset,
                        ),
                        showChevron: true,
                        onTap: () {
                          _handleRecentProjectTap(
                            context,
                          );
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

      // =======================================================================
      // BOTTOM NAV
      // =======================================================================

      bottomNavigationBar:
          AppBottomNavBar(
        currentIndex:
            widget.currentNavIndex,
        onTap: (
          index,
        ) {
          _handleNavTap(
            context,
            index,
          );
        },
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
          style: AppTypography.h3,
        ),
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