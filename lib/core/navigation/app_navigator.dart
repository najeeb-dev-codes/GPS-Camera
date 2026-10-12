import 'package:flutter/material.dart';

import '../../features/camera/live_camera_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Central navigation for every shared bottom-navigation bar in the app.
class AppNavigator {
  AppNavigator._();

  /// Root navigator used by app-wide UI such as the force-update dialog.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static void handleBottomNavTap(BuildContext context, int index) {
    // Do not rebuild a main destination when its selected icon is tapped.
    // A nested screen is a separate route subtree, so the same icon correctly
    // returns to that feature's main destination.
    if (_isAlreadyOnRootDestination(context, index)) return;

    switch (index) {
      case 0:
        _openRootScreen(context, const HomeScreen());
        return;
      case 1:
        _openRootScreen(context, const GalleryScreen());
        return;
      case 2:
        _openCamera(context);
        return;
      case 3:
        _openRootScreen(context, const ProjectsScreen());
        return;
      case 4:
        _openRootScreen(context, const SettingsScreen());
        return;
      default:
        return;
    }
  }

  static void goToHome(BuildContext context) {
    if (_isWidgetInCurrentRoute<HomeScreen>(context)) return;
    _openRootScreen(context, const HomeScreen());
  }

  static void goToGallery(BuildContext context) {
    if (_isWidgetInCurrentRoute<GalleryScreen>(context)) return;
    _openRootScreen(context, const GalleryScreen());
  }

  static void goToCamera(BuildContext context) {
    _openCamera(context);
  }

  /// Opens Camera as the first usable screen after the very first successful
  /// permission onboarding. Home is kept underneath Camera so the Camera
  /// back button returns to the normal app root instead of the permission
  /// flow.
  static void goToCameraAfterPermissionOnboarding(BuildContext context) {
    final navigator = Navigator.of(context);

    navigator.pushAndRemoveUntil<void>(
      _buildRoute(const HomeScreen()),
      (route) => false,
    );

    navigator.push<void>(
      _buildRoute(const LiveCameraScreen()),
    );
  }

  static void goToProjects(BuildContext context) {
    if (_isWidgetInCurrentRoute<ProjectsScreen>(context)) return;
    _openRootScreen(context, const ProjectsScreen());
  }

  static void goToSettings(BuildContext context) {
    if (_isWidgetInCurrentRoute<SettingsScreen>(context)) return;
    _openRootScreen(context, const SettingsScreen());
  }

  static bool _isAlreadyOnRootDestination(
    BuildContext context,
    int index,
  ) {
    return switch (index) {
      0 => _isWidgetInCurrentRoute<HomeScreen>(context),
      1 => _isWidgetInCurrentRoute<GalleryScreen>(context),
      2 => _isWidgetInCurrentRoute<LiveCameraScreen>(context),
      3 => _isWidgetInCurrentRoute<ProjectsScreen>(context),
      4 => _isWidgetInCurrentRoute<SettingsScreen>(context),
      _ => false,
    };
  }

  static bool _isWidgetInCurrentRoute<T extends Widget>(
    BuildContext context,
  ) {
    return context.widget is T ||
        context.findAncestorWidgetOfExactType<T>() != null;
  }

  static void _openCamera(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      _buildRoute(const LiveCameraScreen()),
      // Remove intermediate feature pages while keeping the current root
      // destination below Camera, so Camera's Back button remains useful.
      (route) => route.isFirst,
    );
  }

  static void _openRootScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      _buildRoute(screen),
      // The chosen bottom-navigation destination becomes the new root.
      // This removes every nested screen from the previous feature.
      (route) => false,
    );
  }

  static Route<void> _buildRoute(Widget screen) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
    );
  }
}
