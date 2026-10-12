import 'package:flutter/services.dart';

enum ProjectCoverSource { camera, gallery }

/// Captures or selects a project cover and returns a persistent app-local copy.
class ProjectCoverPicker {
  ProjectCoverPicker._();

  static const MethodChannel _channel = MethodChannel(
    'gps_camera/project_cover',
  );

  static Future<String?> pick({
    ProjectCoverSource source = ProjectCoverSource.gallery,
  }) {
    final method = switch (source) {
      ProjectCoverSource.camera => 'captureProjectCover',
      ProjectCoverSource.gallery => 'pickProjectCover',
    };
    return _channel.invokeMethod<String>(method);
  }
}
