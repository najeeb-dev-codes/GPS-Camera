import 'package:flutter/material.dart';

enum ProjectStatus { active, archived }

class ProjectPhoto {
  const ProjectPhoto({
    required this.id,
    required this.assetPath,
    required this.location,
    required this.capturedAt,
  });

  final String id;
  final String assetPath;
  final String location;
  final DateTime capturedAt;
}

class ProjectData {
  ProjectData({
    required this.id,
    required this.name,
    required this.code,
    required this.client,
    required this.location,
    required this.description,
    required this.coverAsset,
    required this.color,
    required this.status,
    required this.photos,
    required this.locationCount,
    required this.storageBytes,
    required this.updatedAt,
    required this.useStampPreset,
    required this.autoSaveCaptures,
    required this.defaultStampTemplate,
  });

  final String id;
  String name;
  String code;
  String client;
  String location;
  String description;
  String coverAsset;
  Color color;
  ProjectStatus status;
  List<ProjectPhoto> photos;
  int locationCount;
  int storageBytes;
  DateTime updatedAt;
  bool useStampPreset;
  bool autoSaveCaptures;
  String defaultStampTemplate;

  int get photoCount => photos.length;

  String get storageLabel {
    final gb = storageBytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final mb = storageBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}

class ProjectRepository extends ChangeNotifier {
  ProjectRepository._();

  static final ProjectRepository instance = ProjectRepository._();

  final List<ProjectData> _projects = [
    ProjectData(
      id: 'highway-project',
      name: 'Highway Project',
      code: 'HWY-2508',
      client: 'Public Works Department',
      location: 'Palayamkottai, Tirunelveli, TN',
      description: 'Highway construction and inspection documentation.',
      coverAsset: 'assets/images/projects/highway_project.jpg',
      color: const Color(0xFF4F21C8),
      status: ProjectStatus.active,
      photos: _samplePhotos,
      locationCount: 4,
      storageBytes: 2576980378,
      updatedAt: DateTime(2026, 8, 21, 9, 30),
      useStampPreset: true,
      autoSaveCaptures: true,
      defaultStampTemplate: 'Field Work',
    ),
    ProjectData(
      id: 'site-inspection',
      name: 'Site Inspection',
      code: 'SITE-2507',
      client: 'Tirunelveli Corporation',
      location: 'Tirunelveli, Tamil Nadu',
      description: 'Routine construction-site inspection records.',
      coverAsset: 'assets/images/captures/site_inspection.jpg',
      color: const Color(0xFF169C48),
      status: ProjectStatus.active,
      photos: _samplePhotos.take(3).toList(),
      locationCount: 2,
      storageBytes: 786432000,
      updatedAt: DateTime(2026, 8, 21, 8, 15),
      useStampPreset: true,
      autoSaveCaptures: true,
      defaultStampTemplate: 'Classic',
    ),
    ProjectData(
      id: 'bridge-survey',
      name: 'Bridge Survey',
      code: 'BRG-2506',
      client: 'Highways Department',
      location: 'Tirunelveli, Tamil Nadu',
      description: 'Bridge condition and location survey.',
      coverAsset: 'assets/images/captures/road_work.jpg',
      color: const Color(0xFF1473E6),
      status: ProjectStatus.active,
      photos: _samplePhotos.take(5).toList(),
      locationCount: 3,
      storageBytes: 1237319680,
      updatedAt: DateTime(2026, 8, 20, 16, 45),
      useStampPreset: false,
      autoSaveCaptures: true,
      defaultStampTemplate: 'Map Card',
    ),
    ProjectData(
      id: 'completed-survey',
      name: 'Completed Survey',
      code: 'SUR-2504',
      client: 'Survey Department',
      location: 'Tirunelveli, Tamil Nadu',
      description: 'Completed field survey documentation.',
      coverAsset: 'assets/images/captures/site_visit.jpg',
      color: const Color(0xFFFF6A00),
      status: ProjectStatus.archived,
      photos: _samplePhotos.take(4).toList(),
      locationCount: 5,
      storageBytes: 1656750080,
      updatedAt: DateTime(2026, 8, 19, 12),
      useStampPreset: true,
      autoSaveCaptures: false,
      defaultStampTemplate: 'Minimal',
    ),
  ];

  static final List<ProjectPhoto> _samplePhotos = List.generate(9, (index) {
    const assets = [
      'assets/images/captures/site_inspection.jpg',
      'assets/images/captures/road_work.jpg',
      'assets/images/captures/site_visit.jpg',
      'assets/images/projects/highway_project.jpg',
    ];
    return ProjectPhoto(
      id: 'photo-${index + 1}',
      assetPath: assets[index % assets.length],
      location: index.isEven ? 'Palayamkottai, TN' : 'Tirunelveli, TN',
      capturedAt: DateTime(2026, 8, 21).subtract(Duration(days: index)),
    );
  });

  List<ProjectData> get projects => List.unmodifiable(_projects);

  ProjectData? findById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  void add(ProjectData project) {
    _projects.insert(0, project);
    notifyListeners();
  }

  void update(ProjectData project) {
    project.updatedAt = DateTime.now();
    notifyListeners();
  }

  void toggleArchive(ProjectData project) {
    project.status = project.status == ProjectStatus.active
        ? ProjectStatus.archived
        : ProjectStatus.active;
    project.updatedAt = DateTime.now();
    notifyListeners();
  }
}
