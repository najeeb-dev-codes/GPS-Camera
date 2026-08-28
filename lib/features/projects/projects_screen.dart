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
  final _repository = ProjectRepository.instance;
  final _searchController = TextEditingController();
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _searchController.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<ProjectData> get _visibleProjects {
    final query = _searchController.text.trim().toLowerCase();
    return _repository.projects.where((project) {
      final matchesFilter = _filterIndex == 0 ||
          (_filterIndex == 1 && project.status == ProjectStatus.active) ||
          (_filterIndex == 2 && project.status == ProjectStatus.archived);
      final matchesSearch = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.code.toLowerCase().contains(query) ||
          project.location.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _createProject() async {
    final project = await Navigator.of(context).push<ProjectData>(
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    );
    if (project != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: project.id)),
      );
    }
  }

  String _updatedLabel(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(day).inDays;
    if (days <= 0) return 'Updated today';
    if (days == 1) return 'Updated yesterday';
    return 'Updated $days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final projects = _visibleProjects;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Projects',
        showBack: false,
        leadingIcon: Icons.menu,
        actions: [
          IconButton(onPressed: _createProject, icon: const Icon(Icons.add)),
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
                    Padding(
                      padding: EdgeInsets.fromLTRB(padding, 10, padding, 8),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search projects',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
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
                        onChanged: (value) => setState(() => _filterIndex = value),
                        scrollable: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: projects.isEmpty
                          ? const EmptyStatePlaceholder(
                              icon: Icons.folder_off_outlined,
                              title: 'No projects found',
                              description: 'Try another search or create a new project.',
                            )
                          : GridView.builder(
                              padding: EdgeInsets.fromLTRB(padding, 0, padding, 110),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: wide ? 2 : 1,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 14,
                                childAspectRatio: wide ? 3.6 : 3.7,
                              ),
                              itemCount: projects.length,
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                return ProjectCard(
                                  name: project.name,
                                  photoCount: project.photoCount,
                                  updatedLabel: _updatedLabel(project.updatedAt),
                                  imageProvider: AssetImage(project.coverAsset),
                                  showChevron: true,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProjectDetailsScreen(projectId: project.id),
                                    ),
                                  ),
                                );
                              },
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
