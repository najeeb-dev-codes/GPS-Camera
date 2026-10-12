import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';
import 'project_data.dart';
import 'project_details_screen.dart';

class RecentProjectsScreen extends StatefulWidget {
  const RecentProjectsScreen({super.key});

  @override
  State<RecentProjectsScreen> createState() => _RecentProjectsScreenState();
}

class _RecentProjectsScreenState extends State<RecentProjectsScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    final projects = _repository.recentProjects;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Recent Projects'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final padding = wide ? 32.0 : AppSpacing.screenPadding;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : projects.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: const Center(
                              child: EmptyStatePlaceholder(
                                icon: Icons.folder_open_outlined,
                                title: 'No recent projects',
                                description:
                                    'Projects created or with photos added or moved today will show up here.',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              AppSpacing.md,
                              padding,
                              AppSpacing.xxl,
                            ),
                            itemCount: projects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final project = projects[index];
                              final coverPath = project.coverImagePath;
                              final hasCover = coverPath != null &&
                                  !isGeneratedProjectNameCover(coverPath) &&
                                  File(coverPath).existsSync();

                              return ProjectCard(
                                name: project.name,
                                location: project.location,
                                photoCount: project.photoCount,
                                coverColor: Color(project.colorValue),
                                updatedLabel: 'Today',
                                imageProvider: hasCover
                                    ? FileImage(File(coverPath!))
                                    : null,
                                showChevron: true,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProjectDetailsScreen(
                                      projectId: project.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
