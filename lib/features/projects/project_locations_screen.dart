import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/captured_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import 'project_data.dart';
import 'project_map_panel.dart';

class ProjectLocationsScreen extends StatefulWidget {
  const ProjectLocationsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectLocationsScreen> createState() => _ProjectLocationsScreenState();
}

class _ProjectLocationsScreenState extends State<ProjectLocationsScreen> {
  final ProjectRepository _repository = ProjectRepository.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repository.ensureLoaded(refreshPhotos: true);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final project = _repository.findById(widget.projectId);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('${project?.name ?? 'Project'} Locations'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ProjectMapPanel(
              photos: project?.photos ?? const <CapturedPhoto>[],
              fullScreen: true,
            ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}
