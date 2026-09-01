import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../permission/permission_screen.dart';
import 'about_help_screen.dart';
import 'camera_settings_screen.dart';
import 'file_naming_screen.dart';
import 'location_gps_screen.dart';
import 'notifications_screen.dart';
import 'offline_capture_screen.dart';
import 'stamp_defaults_screen.dart';
import 'storage_backup_screen.dart';
import 'theme_screen.dart';
import 'photo_quality_screen.dart';

/// Screen 12 — Settings.
///
/// Grouped list of settings rows (Camera, Stamp Defaults, Location & GPS,
/// Photo Quality, File Naming, Storage & Backup, Offline Capture,
/// Notifications, Privacy), two quick toggles (Save original photo,
/// Offline capture), a Theme row, and an About & Help row.
///
/// Reads/writes [AppSettingsService.instance] so every value shown here
/// (and toggled here) stays in sync with its dedicated detail screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openPermissions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Settings', showBack: false),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 600
                    ? 48.0
                    : AppSpacing.screenPadding;

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    24,
                  ),
                  children: [
                    SettingsListTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      subtitle: 'Aspect ratio, grid, timer',
                      onTap: () => _push(context, const CameraSettingsScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Stamp Defaults',
                      subtitle: 'Default template & visible fields',
                      onTap: () => _push(context, const StampDefaultsScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location & GPS',
                      subtitle: 'Precise vs approximate, accuracy',
                      onTap: () => _push(context, const LocationGpsScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.high_quality_outlined,
                      title: 'Photo Quality',
                      subtitle: 'Resolution & compression',
                      onTap: () => _push(context, const PhotoQualityScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.drive_file_rename_outline,
                      title: 'File Naming',
                      subtitle: 'Prefix, numbering pattern',
                      onTap: () => _push(context, const FileNamingScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.backup_outlined,
                      title: 'Storage & Backup',
                      subtitle: 'Auto backup, cloud storage',
                      onTap: () => _push(context, const StorageBackupScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.cloud_off_outlined,
                      title: 'Offline Capture',
                      subtitle: 'Capture without a connection',
                      onTap: () => _push(context, const OfflineCaptureScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: settings.masterNotifications ? 'On' : 'Off',
                      onTap: () => _push(context, const NotificationsScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Permissions & data controls',
                      onTap: () => _openPermissions(context),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, color: AppColors.border),
                    ),

                    ToggleSettingRow(
                      icon: Icons.save_alt_rounded,
                      title: 'Save original photo',
                      subtitle:
                          'Keep an unstamped copy alongside the geotagged one',
                      value: settings.saveOriginalPhoto,
                      onChanged: (value) =>
                          settings.set(() => settings.saveOriginalPhoto = value),
                    ),
                    ToggleSettingRow(
                      icon: Icons.cloud_off_outlined,
                      title: 'Offline capture',
                      subtitle: 'Store location when offline and sync later',
                      value: settings.offlineCapture,
                      onChanged: (value) =>
                          settings.set(() => settings.offlineCapture = value),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1, color: AppColors.border),
                    ),

                    SettingsListTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            settings.themeModeLabel,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.neutral400,
                          ),
                        ],
                      ),
                      onTap: () => _push(context, const ThemeScreen()),
                    ),
                    SettingsListTile(
                      icon: Icons.info_outline,
                      title: 'About GeoStamp Camera',
                      subtitle: 'Version ${AboutHelpScreen.appVersion}',
                      onTap: () => _push(context, const AboutHelpScreen()),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (index) => AppNavigator.handleBottomNavTap(context, index),
      ),
    );
  }
}