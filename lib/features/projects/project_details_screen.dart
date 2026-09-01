import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../camera/live_camera_screen.dart';
import '../gallery/photo_details_screen.dart';
import 'create_project_screen.dart';
import 'project_data.dart';
import 'project_export_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  int _tabIndex = 0;
  bool _loading = true;
  bool _busy = false;

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
    if (_busy) return;
    setState(() => _busy = true);
    try {
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
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(ProjectData project) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = project.photos
          .map((photo) => File(photo.path))
          .where((file) => file.existsSync())
          .map((file) => XFile(file.path))
          .toList();
      await SharePlus.instance.share(
        ShareParams(
          title: project.name,
          subject: '${project.name} project',
          text: '${project.name}\n${project.location}\n'
              '${project.photoCount} photos • ${project.storageLabel}',
          files: files,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to complete action: $error')),
    );
  }

  Future<void> _toggleArchive(ProjectData project) async {
    await _repository.toggleArchive(project);
    if (mounted) setState(() {});
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 950),
                child: Column(
                  children: [
                    _ProjectHero(
                      project: project,
                      height: wide ? 250 : 185,
                      onBack: () => Navigator.of(context).pop(),
                      onEdit: () => _edit(project),
                      onArchive: () => _toggleArchive(project),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenPadding,
                              14,
                              AppSpacing.screenPadding,
                              8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(project.name,
                                          style: AppTypography.h2),
                                    ),
                                    _StatusBadge(status: project.status),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 17,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(project.location,
                                          style: AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _Metric(Icons.photo_library_outlined,
                                        '${project.photoCount}', 'Photos'),
                                    _Metric(Icons.location_on_outlined,
                                        '${project.locationCount}', 'Locations'),
                                    _Metric(Icons.storage_outlined,
                                        project.storageLabel, 'Storage'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Open Camera',
                                        icon: Icons.camera_alt_outlined,
                                        primary: true,
                                        onTap: _busy
                                            ? null
                                            : () => Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        LiveCameraScreen(
                                                      initialProjectId:
                                                          project.id,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Export',
                                        icon: Icons.picture_as_pdf_outlined,
                                        onTap: _busy ? null : () => _export(project),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Share Project',
                                        icon: Icons.share_outlined,
                                        onTap: _busy ? null : () => _share(project),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AppTabSelector(
                                  tabs: const ['Gallery', 'Map', 'Details'],
                                  selectedIndex: _tabIndex,
                                  onChanged: (index) =>
                                      setState(() => _tabIndex = index),
                                  scrollable: false,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: switch (_tabIndex) {
                              0 => _ProjectGallery(project: project, wide: wide),
                              1 => const _LaterPanel(
                                  icon: Icons.map_outlined,
                                  title: 'Project map is coming next',
                                ),
                              _ => _DetailsPanel(project: project),
                            },
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
        currentIndex: 3,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({
    required this.project,
    required this.height,
    required this.onBack,
    required this.onEdit,
    required this.onArchive,
  });

  final ProjectData project;
  final double height;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final recent = project.recentPhoto;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (recent != null && File(recent.path).existsSync())
            Image.file(File(recent.path), fit: BoxFit.cover)
          else
            Container(
              color: project.color.withValues(alpha: 0.20),
              alignment: Alignment.center,
              child: Icon(Icons.folder_outlined,
                  color: project.color, size: 72),
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
              color: AppColors.white,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
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
                    leading: Icon(project.status == ProjectStatus.active
                        ? Icons.archive_outlined
                        : Icons.unarchive_outlined),
                    title: Text(project.status == ProjectStatus.active
                        ? 'Archive'
                        : 'Restore Project'),
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

class _ProjectGallery extends StatelessWidget {
  const _ProjectGallery({required this.project, required this.wide});

  final ProjectData project;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (project.photos.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.photo_library_outlined,
        title: 'No project photos',
        description: 'Open the camera and save a photo to this project.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 4 : 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.9,
      ),
      itemCount: project.photos.length,
      itemBuilder: (context, index) {
        final photo = project.photos[index];
        return InkWell(
          onTap: () async {
            final deleted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => PhotoDetailsScreen(photo: photo)),
            );
            if (deleted == true) {
              await ProjectRepository.instance.ensureLoaded(refreshPhotos: true);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.border,
                    child: const Icon(Icons.image_outlined),
                  ),
                ),
                const Positioned(
                  top: 5,
                  right: 5,
                  child: _GpsBadge(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == ProjectStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDDF7E5) : AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? '✓ Active' : 'Archived',
        style: TextStyle(
          color: active ? const Color(0xFF137A36) : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: primary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: FittedBox(child: Text(label)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: FittedBox(child: Text(label)),
            ),
    );
  }
}

class _GpsBadge extends StatelessWidget {
  const _GpsBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF7E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('GPS',
          style: TextStyle(
              color: Color(0xFF137A36),
              fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _LaterPanel extends StatelessWidget {
  const _LaterPanel({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.h3),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.project});
  final ProjectData project;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: <MapEntry<String, String>>[
        MapEntry('Project code', project.code),
        MapEntry('Client / Company', project.client),
        MapEntry('Location', project.location),
        MapEntry('Stamp template', project.defaultStampTemplate),
        MapEntry('Description',
            project.description.isEmpty ? 'No description' : project.description),
      ]
          .map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary)),
                subtitle: Text(entry.value, style: AppTypography.bodyMedium),
              ))
          .toList(),
    );
  }
}
