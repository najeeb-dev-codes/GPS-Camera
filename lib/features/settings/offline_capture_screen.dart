import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Offline Capture.
///
/// "Offline Mode Ready" banner, offline-related toggles, downloaded map
/// area, pending address updates, and sync preferences with "Sync Now".
class OfflineCaptureScreen extends StatelessWidget {
  const OfflineCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Offline Capture'),
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
                          AppBanner(
                            tone: BannerTone.success,
                            icon: Icons.cloud_off_outlined,
                            message: settings.offlineCapture
                                ? 'Offline Mode Ready — you can capture photos '
                                    'without internet connection.'
                                : 'Offline Mode is off — enable it to capture '
                                    'without an internet connection.',
                          ),

                          const SizedBox(height: AppSpacing.md),

                          ToggleSettingRow(
                            title: 'Offline Capture',
                            value: settings.offlineCapture,
                            onChanged: (v) => settings.set(() => settings.offlineCapture = v),
                          ),
                          ToggleSettingRow(
                            title: 'Store GPS coordinates offline',
                            value: settings.storeGpsCoordinatesOffline,
                            onChanged: (v) =>
                                settings.set(() => settings.storeGpsCoordinatesOffline = v),
                          ),
                          ToggleSettingRow(
                            title: 'Resolve address when online',
                            value: settings.resolveAddressWhenOnline,
                            onChanged: (v) =>
                                settings.set(() => settings.resolveAddressWhenOnline = v),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          SettingsListTile(
                            icon: Icons.map_outlined,
                            title: 'Download offline maps',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening map download...')),
                              );
                            },
                          ),

                          Text('Downloaded area', style: AppTypography.caption),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const MapPreviewThumbnail(size: 44),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        settings.downloadedAreaName,
                                        style: AppTypography.bodyMedium
                                            .copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${settings.downloadedAreaMb.toStringAsFixed(0)} MB',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.neutral400),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          SettingsListTile(
                            icon: Icons.sync_problem_outlined,
                            title: 'Pending address updates',
                            trailing: Text(
                              '${settings.pendingAddressUpdates} photos',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          ToggleSettingRow(
                            title: 'Auto Sync',
                            value: settings.autoSync,
                            onChanged: (v) => settings.set(() => settings.autoSync = v),
                          ),
                          ToggleSettingRow(
                            title: 'Sync on Wi-Fi only',
                            value: settings.syncOnWifiOnly,
                            onChanged: (v) =>
                                settings.set(() => settings.syncOnWifiOnly = v),
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
                      child: AppPrimaryButton(
                        label: 'Sync Now',
                        icon: Icons.sync_rounded,
                        isLoading: settings.isSyncing,
                        onPressed: settings.syncNow,
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