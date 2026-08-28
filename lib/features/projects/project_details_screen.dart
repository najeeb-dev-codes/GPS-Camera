import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../camera/live_camera_screen.dart';
import 'create_project_screen.dart';
import 'project_data.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final _repository = ProjectRepository.instance;
  int _tabIndex = 0;

  ProjectData? get _project => _repository.findById(widget.projectId);

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() { if (mounted) setState(() {}); }

  Future<void> _edit(ProjectData project) async {
    await Navigator.of(context).push<ProjectData>(
      MaterialPageRoute(builder: (_) => CreateProjectScreen(project: project)),
    );
  }

  void _showActions(ProjectData project) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Project'),
            onTap: () { Navigator.pop(sheetContext); _edit(project); },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Export Report'),
            onTap: () {
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project report is being prepared.')));
            },
          ),
          ListTile(
            leading: Icon(project.status == ProjectStatus.active ? Icons.archive_outlined : Icons.unarchive_outlined),
            title: Text(project.status == ProjectStatus.active ? 'Archive' : 'Restore Project'),
            onTap: () { Navigator.pop(sheetContext); _repository.toggleArchive(project); },
          ),
        ]),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 5),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ]),
      );

  Widget _gallery(ProjectData project, bool wide) {
    if (project.photos.isEmpty) {
      return const EmptyStatePlaceholder(
        icon: Icons.photo_library_outlined,
        title: 'No project photos',
        description: 'Open the camera or import photos to get started.',
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(photo.assetPath, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.border, child: const Icon(Icons.image_outlined))),
            Positioned(
              top: 5, right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDDF7E5), borderRadius: BorderRadius.circular(10)),
                child: const Text('GPS', style: TextStyle(color: Color(0xFF137A36), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _map(ProjectData project) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.map_outlined, size: 72, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('${project.locationCount} saved locations', style: AppTypography.h3),
            const SizedBox(height: 6),
            Text(project.location, textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );

  Widget _details(ProjectData project) => ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (final entry in <String, String>{
            'Project code': project.code,
            'Client / Company': project.client,
            'Location': project.location,
            'Stamp template': project.defaultStampTemplate,
            'Description': project.description.isEmpty ? 'No description' : project.description,
          }.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(entry.value, style: AppTypography.bodyMedium),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Project Details'),
        body: const EmptyStatePlaceholder(icon: Icons.folder_off_outlined, title: 'Project not found', description: 'This project is no longer available.'),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                SizedBox(
                  height: wide ? 230 : 175,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(project.coverAsset, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: project.color.withOpacity(.25), child: const Icon(Icons.landscape_outlined, size: 64))),
                    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black38, Colors.transparent, Colors.black26]))),
                    Positioned(top: 6, left: 4, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: Colors.white))),
                    Positioned(top: 6, right: 4, child: IconButton(onPressed: () => _showActions(project), icon: const Icon(Icons.more_vert, color: Colors.white))),
                  ]),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12, AppSpacing.screenPadding, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(project.name, style: AppTypography.h2)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: project.status == ProjectStatus.active ? const Color(0xFFDDF7E5) : AppColors.border, borderRadius: BorderRadius.circular(20)),
                              child: Text(project.status == ProjectStatus.active ? '✓ Active' : 'Archived', style: TextStyle(color: project.status == ProjectStatus.active ? const Color(0xFF137A36) : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text(project.location, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)))]),
                          const SizedBox(height: 16),
                          Row(children: [
                            _metric(Icons.photo_library_outlined, '${project.photoCount}', 'Photos'),
                            _metric(Icons.location_on_outlined, '${project.locationCount}', 'Locations'),
                            _metric(Icons.storage_outlined, project.storageLabel, 'Storage'),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: AppPrimaryButton(label: 'Open Camera', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveCameraScreen())))),
                            const SizedBox(width: 8),
                            Expanded(child: AppSecondaryButton(label: 'Import Photos', icon: Icons.photo_library_outlined, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose photos from your device.'))))),
                            if (wide) ...[const SizedBox(width: 8), Expanded(child: AppSecondaryButton(label: 'Share Project', icon: Icons.share_outlined, onPressed: () => _showActions(project)))],
                          ]),
                          const SizedBox(height: 12),
                          AppTabSelector(tabs: const ['Gallery', 'Map', 'Details'], selectedIndex: _tabIndex, onChanged: (index) => setState(() => _tabIndex = index), scrollable: false),
                        ]),
                      ),
                      Expanded(child: switch (_tabIndex) { 0 => _gallery(project, wide), 1 => _map(project), _ => _details(project) }),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3, onTap: (index) => AppNavigator.handleBottomNavTap(context, index)),
    );
  }
}
