import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_input_limits.dart';
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
  static const List<String> _filters = <String>[
    'All',
    'Active',
    'Archived',
  ];

  final ProjectRepository _repository = ProjectRepository.instance;
  final TextEditingController _search = TextEditingController();
  int _filterIndex = 0;
  bool _loading = true;
  bool _showSearch = false;

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

  void _toggleSearch() {
    final showSearch = !_showSearch;
    setState(() => _showSearch = showSearch);
    if (!showSearch) {
      _search.clear();
      FocusScope.of(context).unfocus();
    }
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

  Widget _buildFilterBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final selected = _filterIndex == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _filters.length - 1 ? 4 : 0,
              ),
              child: Material(
                color: selected
                    ? AppColors.isDarkMode
                        ? AppColors.primarySurface
                        : AppColors.lightSurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () => setState(() => _filterIndex = index),
                  child: Center(
                    child: Text(
                      _filters[index],
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
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Projects',
        showBack: false,
        showConnectivityStatus: true,
        actions: [
          IconButton(
            tooltip: _showSearch ? 'Close search' : 'Search projects',
            onPressed: _toggleSearch,
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
        ],
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
                    if (_showSearch)
                      Padding(
                        padding: EdgeInsets.fromLTRB(padding, 8, padding, 10),
                        child: TextField(
                          controller: _search,
                          maxLength: AppInputLimits.search,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search projects',
                            counterText: '',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    if (!_showSearch) const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: _buildFilterBar(),
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
                                    updatedLabel: _updatedLabel(
                                        _projects[index].updatedAt),
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(
            format: AdDisplayFormat.largeBanner,
            reserveSpaceWhileLoading: true,
          ),
          AppBottomNavBar(
            currentIndex: 3,
            onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
          ),
        ],
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
    final coverColor = Color(project.colorValue);
    final isLightCover = coverColor.value == 0xFFFFFFFF;
    final coverPath = project.coverImagePath;
    final hasCoverImage = coverPath != null &&
        coverPath.isNotEmpty &&
        !isGeneratedProjectNameCover(coverPath) &&
        File(coverPath).existsSync();

    Widget buildInitialsCover() => Container(
          width: 84,
          height: 84,
          color: coverColor,
          alignment: Alignment.center,
          child: Text(
            _projectInitials(project.name),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppTypography.h2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isLightCover ? Colors.black : Colors.white,
            ),
          ),
        );

    return Material(
      color: AppColors.surface,
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
                child: hasCoverImage
                    ? Image.file(
                        File(coverPath!),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            buildInitialsCover(),
                      )
                    : buildInitialsCover(),
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
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: project.status == ProjectStatus.active
                        ? const Color(0xFFDDF7E5)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    project.status == ProjectStatus.active
                        ? 'Active'
                        : 'Archived',
                    style: TextStyle(
                      color: project.status == ProjectStatus.active
                          ? const Color(0xFF137A36)
                          : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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


String _projectInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  return words.length == 1
      ? String.fromCharCodes(words.first.runes.take(2)).toUpperCase()
      : words
          .take(2)
          .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
          .join();
}
