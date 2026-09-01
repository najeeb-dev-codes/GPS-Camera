import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'create_project_screen.dart';
import 'project_data.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  final TextEditingController _search = TextEditingController();
  int _filterIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    _search.addListener(_refresh);
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
    _search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  List<ProjectData> get _projects {
    final query = _search.text.trim().toLowerCase();
    return _repository.projects.where((project) {
      final statusMatches = _filterIndex == 0 ||
          (_filterIndex == 1 && project.status == ProjectStatus.active) ||
          (_filterIndex == 2 && project.status == ProjectStatus.archived);
      final searchMatches = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.code.toLowerCase().contains(query) ||
          project.location.toLowerCase().contains(query);
      return statusMatches && searchMatches;
    }).toList();
  }

  Future<void> _createProject() async {
    final project = await Navigator.of(context).push<ProjectData>(
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
    if (project != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: project.id),
        ),
      );
    }
  }

  String _updatedLabel(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Updated now';
    if (difference.inHours < 1) return 'Updated ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Updated ${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Updated yesterday';
    return 'Updated ${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Projects'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final padding = wide ? 32.0 : AppSpacing.screenPadding;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 8, padding, 10),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Search projects',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: AppTabSelector(
                        tabs: const ['All', 'Active', 'Archived'],
                        selectedIndex: _filterIndex,
                        onChanged: (index) => setState(() => _filterIndex = index),
                        scrollable: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _projects.isEmpty
                              ? EmptyStatePlaceholder(
                                  icon: Icons.folder_open_outlined,
                                  title: 'No projects found',
                                  description: _search.text.isEmpty
                                      ? 'Create your first project to organize captured photos.'
                                      : 'Try another project name or location.',
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                      padding, 0, padding, 110),
                                  itemCount: _projects.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _ProjectListCard(
                                    project: _projects[index],
                                    updatedLabel:
                                        _updatedLabel(_projects[index].updatedAt),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProjectDetailsScreen(
                                          projectId: _projects[index].id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  const _ProjectListCard({
    required this.project,
    required this.updatedLabel,
    required this.onTap,
  });

  final ProjectData project;
  final String updatedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recent = project.recentPhoto;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: recent != null && File(recent.path).existsSync()
                    ? Image.file(File(recent.path),
                        width: 84, height: 72, fit: BoxFit.cover)
                    : Container(
                        width: 84,
                        height: 72,
                        color: project.color.withValues(alpha: 0.16),
                        alignment: Alignment.center,
                        child: Icon(Icons.folder_outlined,
                            color: project.color, size: 34),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium),
                    const SizedBox(height: 3),
                    Text(project.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('${project.photoCount} photos • $updatedLabel',
                        style: AppTypography.tiny
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: project.status == ProjectStatus.active
                      ? const Color(0xFFDDF7E5)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  project.status == ProjectStatus.active ? 'Active' : 'Archived',
                  style: TextStyle(
                    color: project.status == ProjectStatus.active
                        ? const Color(0xFF137A36)
                        : AppColors.textSecondary,
                    fontSize: 10,
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
