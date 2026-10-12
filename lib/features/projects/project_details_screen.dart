import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/project_cover_layout.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/ad_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'create_project_screen.dart';
import 'project_data.dart';
import 'project_export_service.dart';
import 'project_locations_screen.dart';
import 'project_photos_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  bool _loading = true;
  bool _exporting = false;
  bool _deleting = false;

  ProjectData? get _project => _repository.findById(widget.projectId);

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

  Future<void> _edit(ProjectData project) async {
    await Navigator.of(context).push<ProjectData>(
      MaterialPageRoute(builder: (_) => CreateProjectScreen(project: project)),
    );
  }

  Future<void> _export(ProjectData project) async {
    if (_exporting) return;

    if (project.photos.isEmpty) {
      AppTopToast.show(
        context,
        message: 'Add at least one photo to this project before exporting.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      await AdService.instance.showInterstitialIfReady();
      if (!mounted) return;

      final report = await ProjectExportService.createReport(project);
      await SharePlus.instance.share(
        ShareParams(
          title: '${project.name} report',
          subject: '${project.name} project report',
          files: <XFile>[XFile(report.path, mimeType: 'application/pdf')],
          fileNameOverrides: <String>[report.uri.pathSegments.last],
        ),
      );
    } catch (error) {
      if (mounted) {
        AppTopToast.show(
          context,
          message: 'Unable to export project: $error',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _toggleArchive(ProjectData project) async {
    final willArchive = project.status != ProjectStatus.archived;
    await _repository.toggleArchive(project);
    if (!mounted) return;
    AppTopToast.show(
      context,
      message: willArchive
          ? 'Project “${project.name}” archived.'
          : 'Project “${project.name}” restored.',
      icon: willArchive
          ? Icons.archive_outlined
          : Icons.unarchive_outlined,
      backgroundColor: willArchive ? Colors.orange : Colors.green,
    );
  }

  Future<void> _deleteProject(ProjectData project) async {
    if (_deleting) return;
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete project?',
      message: '“${project.name}” will be permanently deleted. Its captured '
          'photos will remain available in the main Gallery.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _repository.delete(project.id);
      if (!mounted) return;
      AppTopToast.show(
        context,
        message: 'Project “${project.name}” deleted.',
        icon: Icons.delete_outline_rounded,
        backgroundColor: Colors.red,
      );
      AppNavigator.goToProjects(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppTopToast.show(
        context,
        message: 'Unable to delete project: $error',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  void _openPhotos(ProjectData project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectPhotosScreen(projectId: project.id),
      ),
    );
  }

  void _openLocations(ProjectData project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectLocationsScreen(projectId: project.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final project = _project;
    if (project == null) {
      return const Scaffold(
        body: EmptyStatePlaceholder(
          icon: Icons.folder_off_outlined,
          title: 'Project not found',
          description: 'This project is no longer available.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final padding = wide ? 32.0 : AppSpacing.screenPadding;
            final contentWidth = constraints.maxWidth > 900
                ? 900.0
                : constraints.maxWidth;
            final coverHeight =
                contentWidth / ProjectCoverLayout.aspectRatio;
            final actionCardHeight = wide ? 116.0 : 104.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: coverHeight + (actionCardHeight / 2),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: coverHeight,
                              child: _ProjectCover(
                                project: project,
                                height: coverHeight,
                                onBack: () => Navigator.of(context).pop(),
                                onEdit: () => _edit(project),
                                onArchive: () => _toggleArchive(project),
                                onDelete: () => _deleteProject(project),
                                deleting: _deleting,
                              ),
                            ),
                            Positioned(
                              top: coverHeight - (actionCardHeight / 2),
                              left: padding,
                              right: padding,
                              height: actionCardHeight,
                              child: _ProjectActionsCard(
                                photoCount: project.photoCount,
                                locationCount: project.locationCount,
                                exporting: _exporting,
                                onPhotos: () => _openPhotos(project),
                                onLocations: () => _openLocations(project),
                                onExport: () => _export(project),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        24,
                        padding,
                        28,
                      ),
                      sliver: SliverList.list(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.folder,
                                  size: 24,
                                  color: Color(project.colorValue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: AppTypography.h2,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 24,
                                color: Color(project.colorValue),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  project.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _ProjectInformation(project: project),
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          AppBottomNavBar(
            currentIndex: 3,
            onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
          ),
        ],
      ),
    );
  }
}

class _ProjectCover extends StatelessWidget {
  const _ProjectCover({
    required this.project,
    required this.height,
    required this.onBack,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    required this.deleting,
  });

  final ProjectData project;
  final double height;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final path = project.coverImagePath;
    final available = path != null &&
        !isGeneratedProjectNameCover(path) && File(path).existsSync();
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (available)
            ColoredBox(
              color: AppColors.mutedSurface,
              child: Image.file(
                File(path!),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 72,
                    color: AppColors.neutral400,
                  ),
                ),
              ),
            )
          else
            Container(
              color: Color(project.colorValue),
              alignment: Alignment.center,
              child: Text(
                _projectInitials(project.name),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: project.colorValue == 0xFFFFFFFF
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black26],
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              color: AppColors.surface,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Project'),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(
                      project.status == ProjectStatus.active
                          ? Icons.archive_outlined
                          : Icons.unarchive_outlined,
                    ),
                    title: Text(
                      project.status == ProjectStatus.active
                          ? 'Archive'
                          : 'Restore Project',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: !deleting,
                  child: const ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Delete Project',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectActionsCard extends StatelessWidget {
  const _ProjectActionsCard({
    required this.photoCount,
    required this.locationCount,
    required this.exporting,
    required this.onPhotos,
    required this.onLocations,
    required this.onExport,
  });

  final int photoCount;
  final int locationCount;
  final bool exporting;
  final VoidCallback onPhotos;
  final VoidCallback onLocations;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            _ProjectAction(
              icon: Icons.photo_library_outlined,
              value: 'Photos ($photoCount)',
              onTap: onPhotos,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            _ProjectAction(
              icon: Icons.location_on_outlined,
              value: 'Locations ($locationCount)',
              onTap: onLocations,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            _ProjectAction(
              icon: Icons.picture_as_pdf_outlined,
              value: 'Export',
              busy: exporting,
              onTap: exporting ? null : onExport,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectAction extends StatelessWidget {
  const _ProjectAction({
    required this.icon,
    required this.value,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 25),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  busy ? 'Exporting' : value,
                  maxLines: 1,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectInformation extends StatelessWidget {
  const _ProjectInformation({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Project code', project.code),
      MapEntry('Client / Company', project.client),
      MapEntry('Location', project.location),
      MapEntry(
        'Description',
        project.description.isEmpty ? 'No description' : project.description,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: rows
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

String _projectInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'P';
  if (words.length == 1) {
    return String.fromCharCodes(words.first.runes.take(2)).toUpperCase();
  }
  return words
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
      .join();
}
