import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Notifications.
///
/// Master toggle, per-event toggles, reminder frequency, sound/vibration,
/// and quiet hours. Individual toggles are disabled while the master
/// switch is off, matching how notification settings behave on iOS/Android.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _reminderOptions = ['Daily', 'Weekly', 'Off'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Notifications'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            final enabled = settings.masterNotifications;

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
                          ToggleSettingRow(
                            title: 'Master Notifications',
                            value: settings.masterNotifications,
                            onChanged: (v) =>
                                settings.set(() => settings.masterNotifications = v),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          Opacity(
                            opacity: enabled ? 1 : 0.4,
                            child: IgnorePointer(
                              ignoring: !enabled,
                              child: Column(
                                children: [
                                  ToggleSettingRow(
                                    title: 'Capture Saved',
                                    value: settings.notifyCaptureSaved,
                                    onChanged: (v) =>
                                        settings.set(() => settings.notifyCaptureSaved = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'GPS Accuracy Warning',
                                    value: settings.notifyGpsAccuracyWarning,
                                    onChanged: (v) => settings
                                        .set(() => settings.notifyGpsAccuracyWarning = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Backup Completed',
                                    value: settings.notifyBackupCompleted,
                                    onChanged: (v) => settings
                                        .set(() => settings.notifyBackupCompleted = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Backup Failed',
                                    value: settings.notifyBackupFailed,
                                    onChanged: (v) =>
                                        settings.set(() => settings.notifyBackupFailed = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Storage Almost Full',
                                    value: settings.notifyStorageAlmostFull,
                                    onChanged: (v) => settings
                                        .set(() => settings.notifyStorageAlmostFull = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Location Services Disabled',
                                    value: settings.notifyLocationServicesDisabled,
                                    onChanged: (v) => settings.set(
                                        () => settings.notifyLocationServicesDisabled = v),
                                  ),

                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                    child: Divider(height: 1, color: AppColors.border),
                                  ),

                                  DropdownSettingRow<String>(
                                    title: 'Reminder to Sync',
                                    value: settings.reminderToSync,
                                    items: _reminderOptions,
                                    onChanged: (v) =>
                                        settings.set(() => settings.reminderToSync = v!),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Sound',
                                    value: settings.notificationSound,
                                    onChanged: (v) =>
                                        settings.set(() => settings.notificationSound = v),
                                  ),
                                  ToggleSettingRow(
                                    title: 'Vibration',
                                    value: settings.notificationVibration,
                                    onChanged: (v) => settings
                                        .set(() => settings.notificationVibration = v),
                                  ),

                                  SettingsListTile(
                                    icon: Icons.bedtime_outlined,
                                    title: 'Quiet Hours',
                                    trailing: Text(
                                      settings.quietHoursLabel,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () => _pickQuietHours(context, settings),
                                  ),
                                ],
                              ),
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
                      child: AppPrimaryButton(
                        label: 'Save Preferences',
                        icon: Icons.notifications_active_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification preferences saved')),
                          );
                        },
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

  Future<void> _pickQuietHours(
    BuildContext context,
    AppSettingsService settings,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: settings.quietHoursStart,
      helpText: 'Quiet hours start',
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: settings.quietHoursEnd,
      helpText: 'Quiet hours end',
    );
    if (end == null) return;

    settings.set(() {
      settings.quietHoursStart = start;
      settings.quietHoursEnd = end;
    });
  }
}