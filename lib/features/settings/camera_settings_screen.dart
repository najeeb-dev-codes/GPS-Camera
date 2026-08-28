



import 'package:flutter/material.dart';

import '../../core/models/camera_aspect_ratio.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Camera Settings.
///
/// Default camera, capture mode, aspect ratio, grid/level/focus/mirror
/// toggles, shutter sound, volume key action, timer, and "Save original
/// photo" — with a bottom "Reset Camera Settings" action.
class CameraSettingsScreen extends StatelessWidget {
  const CameraSettingsScreen({super.key});

  static const _cameras = ['Back Camera', 'Front Camera'];
  static const _captureModes = ['Photo', 'Video'];
  static const _volumeActions = ['Capture', 'Zoom', 'None'];
  static const _timers = ['Off', '3s', '5s', '10s'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Camera Settings'),
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
                          DropdownSettingRow<String>(
                            title: 'Default camera',
                            value: settings.defaultCamera,
                            items: _cameras,
                            onChanged: (v) =>
                                settings.set(() => settings.defaultCamera = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Capture mode',
                            value: settings.captureMode,
                            items: _captureModes,
                            onChanged: (v) =>
                                settings.set(() => settings.captureMode = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Aspect Ratio',
                            value: settings.aspectRatio,
                            items: CameraAspectRatioOption.labels,
                            onChanged: (v) =>
                                settings.set(() => settings.aspectRatio = v!),
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          ToggleSettingRow(
                            title: 'Grid Lines',
                            value: settings.gridLines,
                            onChanged: (v) =>
                                settings.set(() => settings.gridLines = v),
                          ),
                          ToggleSettingRow(
                            title: 'Level Indicator',
                            value: settings.levelIndicator,
                            onChanged: (v) =>
                                settings.set(() => settings.levelIndicator = v),
                          ),
                          ToggleSettingRow(
                            title: 'GPS Accuracy Meter',
                            value: settings.showGpsAccuracyMeter,
                            onChanged: (value) {
                              settings.set(() {
                                settings.showGpsAccuracyMeter = value;
                              });
                            },
                          ),
                          ToggleSettingRow(
                            title: 'Tap to Focus',
                            value: settings.tapToFocus,
                            onChanged: (v) =>
                                settings.set(() => settings.tapToFocus = v),
                          ),
                          ToggleSettingRow(
                            title: 'Mirror Selfies',
                            value: settings.mirrorSelfies,
                            onChanged: (v) =>
                                settings.set(() => settings.mirrorSelfies = v),
                          ),
                          ToggleSettingRow(
                            title: 'Shutter Sound',
                            value: settings.shutterSound,
                            onChanged: (v) =>
                                settings.set(() => settings.shutterSound = v),
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Volume Key Action',
                            value: settings.volumeKeyAction,
                            items: _volumeActions,
                            onChanged: (v) => settings
                                .set(() => settings.volumeKeyAction = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Timer',
                            value: settings.timer,
                            items: _timers,
                            onChanged: (v) =>
                                settings.set(() => settings.timer = v!),
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          ToggleSettingRow(
                            title: 'Save original photo',
                            value: settings.saveOriginalPhoto,
                            onChanged: (v) => settings
                                .set(() => settings.saveOriginalPhoto = v),
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
                      child: AppSecondaryButton(
                        label: 'Reset Camera Settings',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          settings.resetCameraSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Camera settings reset')),
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
}
