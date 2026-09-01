import 'package:flutter/material.dart';

import '../../features/camera/live_camera_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppNavigator {
  AppNavigator._();

  static void handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        goToHome(context);
        break;

      case 1:
        goToGallery(context);
        break;

      case 2:
        goToCamera(context);
        break;

      case 3:
        goToProjects(context);
        break;

      case 4:
        goToSettings(context);
        break;
    }
  }

  static void goToHome(BuildContext context) {
    _replaceScreen(context, const HomeScreen());
  }

  static void goToGallery(BuildContext context) {
    _replaceScreen(context, const GalleryScreen());
  }

  static void goToCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LiveCameraScreen(),
      ),
    );
  }

  static void goToProjects(BuildContext context) {
    _replaceScreen(
      context,
      const ProjectsScreen(),
    );
  }

  static void goToSettings(BuildContext context) {
    _replaceScreen(
      context,
      const SettingsScreen(),
    );
  }

  static void _replaceScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }
}