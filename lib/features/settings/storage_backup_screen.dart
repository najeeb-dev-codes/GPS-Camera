import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Storage & Backup.
///
/// Storage usage bar, save location, folder/backup toggles, backup
/// schedule, and a live "last backup" summary with "Back Up Now" /
/// "Manage Storage" actions.
class StorageBackupScreen extends StatelessWidget {
  const StorageBackupScreen({super.key});

  static const _schedules = ['Daily', 'Weekly', 'Manual'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Storage & Backup'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 600 ? 48.0 : AppSpacing.screenPadding;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          24,
                        ),
                        children: [
                          Text(
                            'Storage Used',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: settings.storageUsedFraction,
                              minHeight: 8,
                              backgroundColor: AppColors.neutral200,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${settings.storageUsedGb.toStringAsFixed(1)} GB of '
                            '${settings.storageTotalGb.toStringAsFixed(0)} GB'
                            '   •   ${settings.storageUsedPercent}%',
                            style: AppTypography.caption,
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          SettingsListTile(
                            icon: Icons.folder_outlined,
                            title: 'Save Location',
                            trailing: Text(
                              settings.saveLocation,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),

                          ToggleSettingRow(
                            title: 'Create project folders',
                            value: settings.createProjectFolders,
                            onChanged: (v) =>
                                settings.set(() => settings.createProjectFolders = v),
                          ),
                          ToggleSettingRow(
                            title: 'Cloud Backup',
                            value: settings.cloudBackup,
                            onChanged: (v) => settings.set(() => settings.cloudBackup = v),
                          ),
                          ToggleSettingRow(
                            title: 'Backup Over Wi-Fi Only',
                            value: settings.backupOverWifiOnly,
                            onChanged: (v) =>
                                settings.set(() => settings.backupOverWifiOnly = v),
                          ),

                          DropdownSettingRow<String>(
                            title: 'Auto Backup',
                            value: settings.autoBackup,
                            items: _schedules,
                            onChanged: (v) => settings.set(() => settings.autoBackup = v!),
                          ),

                          ToggleSettingRow(
                            title: 'Backup Original Photos',
                            value: settings.backupOriginalPhotos,
                            onChanged: (v) =>
                                settings.set(() => settings.backupOriginalPhotos = v),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_done_outlined,
                                  color: AppColors.primary,
                                  size: AppSizes.iconMd,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Last backup', style: AppTypography.caption),
                                      Text(
                                        settings.isBackingUp
                                            ? 'Backing up…'
                                            : settings.lastBackupLabel,
                                        style: AppTypography.bodyMedium
                                            .copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        16,
                      ),
                      child: Column(
                        children: [
                          AppPrimaryButton(
                            label: 'Back Up Now',
                            icon: Icons.backup_outlined,
                            isLoading: settings.isBackingUp,
                            onPressed: settings.runBackupNow,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppSecondaryButton(
                            label: 'Manage Storage',
                            icon: Icons.storage_outlined,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening storage manager...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}