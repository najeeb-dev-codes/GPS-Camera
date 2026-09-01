import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/captured_photo_service.dart';

enum ProjectStatus { active, archived }

class ProjectData {
  ProjectData({
    required this.id,
    required this.name,
    required this.code,
    required this.client,
    required this.location,
    required this.description,
    required this.color,
    required this.status,
    required this.updatedAt,
    required this.useStampPreset,
    required this.autoSaveCaptures,
    required this.defaultStampTemplate,
    List<String>? photoIds,
  }) : photoIds = photoIds ?? <String>[];

  final String id;
  String name;
  String code;
  String client;
  String location;
  String description;
  Color color;
  ProjectStatus status;
  DateTime updatedAt;
  bool useStampPreset;
  bool autoSaveCaptures;
  String defaultStampTemplate;
  final List<String> photoIds;

  List<CapturedPhoto> _photos = <CapturedPhoto>[];
  List<CapturedPhoto> get photos => List.unmodifiable(_photos);
  int get photoCount => _photos.length;

  int get locationCount => _photos
      .map((photo) {
        final latitude = photo.stampData?.latitude;
        final longitude = photo.stampData?.longitude;
        if (latitude != null && longitude != null) {
          // Four decimal places groups fixes captured at approximately the
          // same physical point while keeping genuinely different places.
          return '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
        }
        return photo.location.trim().toLowerCase();
      })
      .where((location) => location.isNotEmpty)
      .toSet()
      .length;

  int get storageBytes => _photos.fold<int>(
        0,
        (total, photo) =>
            total + (photo.captureMetadata?.fileSizeBytes ?? 0),
      );

  CapturedPhoto? get recentPhoto => _photos.isEmpty ? null : _photos.first;

  String get storageLabel {
    final bytes = storageBytes;
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  void hydratePhotos(Iterable<CapturedPhoto> allPhotos) {
    final allowed = photoIds.toSet();
    _photos = allPhotos
        .where((photo) =>
            photo.projectId == id ||
            (photo.projectId == null && allowed.contains(photo.id)))
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    for (final photo in _photos) {
      if (!photoIds.contains(photo.id)) photoIds.add(photo.id);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'code': code,
        'client': client,
        'location': location,
        'description': description,
        'color': color.toARGB32(),
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
        'useStampPreset': useStampPreset,
        'autoSaveCaptures': autoSaveCaptures,
        'defaultStampTemplate': defaultStampTemplate,
        'photoIds': photoIds,
      };

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Untitled Project',
      code: (json['code'] as String?) ?? '',
      client: (json['client'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      color: Color((json['color'] as num?)?.toInt() ?? 0xFF4F21C8),
      status: json['status'] == ProjectStatus.archived.name
          ? ProjectStatus.archived
          : ProjectStatus.active,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      useStampPreset: json['useStampPreset'] as bool? ?? true,
      autoSaveCaptures: json['autoSaveCaptures'] as bool? ?? false,
      defaultStampTemplate:
          (json['defaultStampTemplate'] as String?) ?? 'Map Proof',
      photoIds: (json['photoIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }
}

class ProjectRepository extends ChangeNotifier {
  ProjectRepository._();

  static final ProjectRepository instance = ProjectRepository._();
  static const String _storageKey = 'gps_camera_projects_v2';

  final List<ProjectData> _projects = <ProjectData>[];
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;
  List<ProjectData> get projects {
    final result = List<ProjectData>.of(_projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(result);
  }

  Future<void> ensureLoaded({bool refreshPhotos = false}) async {
    if (_loading) {
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return;
    }
    if (_loaded && !refreshPhotos) return;

    _loading = true;
    try {
      if (!_loaded) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        _projects.clear();
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          for (final item in decoded) {
            try {
              _projects.add(
                ProjectData.fromJson(Map<String, dynamic>.from(item as Map)),
              );
            } catch (_) {
              // Ignore only the damaged project and keep remaining projects.
            }
          }
        }
        _loaded = true;
      }

      final photos = await CapturedPhotoService.loadPhotos();
      for (final project in _projects) {
        project.hydratePhotos(photos);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ProjectData? findById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Future<void> add(ProjectData project) async {
    await ensureLoaded();
    _projects.removeWhere((item) => item.id == project.id);
    _projects.insert(0, project);
    await _persist();
  }

  Future<void> update(ProjectData project) async {
    project.updatedAt = DateTime.now();
    await _persist();
  }

  Future<void> toggleArchive(ProjectData project) async {
    project.status = project.status == ProjectStatus.active
        ? ProjectStatus.archived
        : ProjectStatus.active;
    project.updatedAt = DateTime.now();
    await _persist();
  }

  Future<void> attachPhoto(String projectId, CapturedPhoto photo) async {
    await ensureLoaded();
    final project = findById(projectId);
    if (project == null) throw Exception('Selected project was not found.');
    if (!project.photoIds.contains(photo.id)) project.photoIds.add(photo.id);
    project.updatedAt = photo.capturedAt;
    await ensureLoaded(refreshPhotos: true);
    await _persist();
  }

  Future<void> movePhotosToProject(
    String projectId,
    Iterable<CapturedPhoto> photos,
  ) async {
    await ensureLoaded();
    final target = findById(projectId);
    if (target == null) throw Exception('Selected project was not found.');

    final movedIds = photos.map((photo) => photo.id).toSet();
    for (final project in _projects) {
      project.photoIds.removeWhere(movedIds.contains);
    }
    for (final id in movedIds) {
      if (!target.photoIds.contains(id)) target.photoIds.add(id);
    }
    target.updatedAt = DateTime.now();
    await ensureLoaded(refreshPhotos: true);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _storageKey,
      jsonEncode(_projects.map((project) => project.toJson()).toList()),
    );
    if (!saved) throw Exception('Unable to save project information.');
    notifyListeners();
  }
}
