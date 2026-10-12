import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
    required this.status,
    required this.updatedAt,
    this.recentActivityAt,
    this.coverImagePath,
    this.colorValue = 0xFF6D28D9,
    List<String>? photoIds,
  }) : photoIds = photoIds ?? <String>[];

  final String id;
  String name;
  String code;
  String client;
  String location;
  String description;
  String? coverImagePath;
  int colorValue;
  ProjectStatus status;
  DateTime updatedAt;
  DateTime? recentActivityAt;
  final List<String> photoIds;

  List<CapturedPhoto> _photos = <CapturedPhoto>[];
  List<CapturedPhoto> get photos => List.unmodifiable(_photos);
  int get photoCount => _photos.length;

  int get locationCount => _photos
      .map(_locationKey)
      .where((location) => location.isNotEmpty)
      .toSet()
      .length;

  static String _locationKey(CapturedPhoto photo) {
    final stamp = photo.stampData;
    final candidates = <String?>[
      stamp?.street,
      stamp?.area, // sub-locality/village from reverse geocoding
      stamp?.city,
      stamp?.title,
      photo.location,
    ];
    for (final candidate in candidates) {
      final normalized = (candidate ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  int get storageBytes => _photos.fold<int>(
        0,
        (total, photo) =>
            total + (photo.captureMetadata?.fileSizeBytes ?? 0),
      );

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
        'coverImagePath': coverImagePath,
        'colorValue': colorValue,
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
        'recentActivityAt': recentActivityAt?.toIso8601String(),
        'photoIds': photoIds,
      };

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    final storedCoverImagePath = (json['coverImagePath'] as String?)?.trim();
    final coverImagePath = isGeneratedProjectNameCover(storedCoverImagePath)
        ? null
        : storedCoverImagePath;
    return ProjectData(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Untitled Project',
      code: (json['code'] as String?) ?? '',
      client: (json['client'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      coverImagePath:
          coverImagePath == null || coverImagePath.isEmpty ? null : coverImagePath,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF6D28D9,
      status: json['status'] == ProjectStatus.archived.name
          ? ProjectStatus.archived
          : ProjectStatus.active,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      recentActivityAt: DateTime.tryParse(
        json['recentActivityAt'] as String? ?? '',
      ),
      photoIds: (json['photoIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }
}

bool isGeneratedProjectNameCover(String? path) {
  if (path == null || path.isEmpty) return false;
  final normalizedPath = path.replaceAll('\\', '/');
  final segments = normalizedPath.split('/');
  if (segments.length < 2) return false;
  final parentDirectory = segments[segments.length - 2];
  final fileName = segments.last;
  // Generated initials covers use the exact project_<timestamp>.png format.
  // Do not classify cropped user-selected images such as
  // project_cover_crop_<timestamp>.png as generated covers.
  return parentDirectory == 'project_covers' &&
      RegExp(r'^project_\d+\.png$').hasMatch(fileName);
}

class ProjectRepository extends ChangeNotifier {
  ProjectRepository._() {
    _scheduleRecentActivityExpiry();
  }

  static final ProjectRepository instance = ProjectRepository._();
  static const String _storageKey = 'gps_camera_projects_v2';

  final List<ProjectData> _projects = <ProjectData>[];
  Timer? _recentActivityTimer;
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;
  List<ProjectData> get projects {
    final result = List<ProjectData>.of(_projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(result);
  }

  List<ProjectData> get recentProjects {
    final now = DateTime.now();
    final result = _projects
        .where((project) {
          final activity = project.recentActivityAt?.toLocal();
          return activity != null &&
              activity.year == now.year &&
              activity.month == now.month &&
              activity.day == now.day;
        })
        .toList()
      ..sort((a, b) =>
          b.recentActivityAt!.compareTo(a.recentActivityAt!));
    return List.unmodifiable(result);
  }

  void _scheduleRecentActivityExpiry() {
    _recentActivityTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _recentActivityTimer = Timer(duration, () {
      notifyListeners();
      _scheduleRecentActivityExpiry();
    });
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
    project.recentActivityAt ??= DateTime.now();
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

  Future<void> delete(String projectId) async {
    await ensureLoaded();
    final project = findById(projectId);
    if (project == null) return;

    await CapturedPhotoService.clearProjectAssignment(projectId);
    _projects.removeWhere((item) => item.id == projectId);
    await _persist();

    final coverPath = project.coverImagePath;
    if (coverPath != null && coverPath.isNotEmpty) {
      try {
        final cover = File(coverPath);
        if (await cover.exists()) await cover.delete();
      } catch (_) {
        // Project deletion remains successful if cover cleanup is unavailable.
      }
    }
  }

  Future<void> attachPhoto(String projectId, CapturedPhoto photo) async {
    await ensureLoaded();
    final project = findById(projectId);
    if (project == null) throw Exception('Selected project was not found.');
    if (!project.photoIds.contains(photo.id)) project.photoIds.add(photo.id);
    project.recentActivityAt = DateTime.now();
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
    if (movedIds.isEmpty) return;

    for (final project in _projects) {
      project.photoIds.removeWhere(movedIds.contains);
    }
    for (final id in movedIds) {
      if (!target.photoIds.contains(id)) target.photoIds.add(id);
    }
    target.recentActivityAt = DateTime.now();
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

