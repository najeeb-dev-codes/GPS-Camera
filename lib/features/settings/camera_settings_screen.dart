import 'package:flutter/material.dart';

import '../../core/models/camera_aspect_ratio.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Camera.
///
/// Default camera, capture mode, aspect ratio, grid/level/focus/mirror
/// toggles, shutter sound and timer, with a bottom reset action. Volume-key
/// action and original-photo saving are available directly on Settings.
class CameraSettingsScreen extends StatelessWidget {
  const CameraSettingsScreen({super.key});

  static const _cameras = ['Back Camera', 'Front Camera'];
  static const _captureModes = ['Photo'];
  static const _timers = ['Off', '3s', '5s', '10s'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Camera',
        actions: [
          TextButton(
            onPressed: () {
              settings.resetCameraSettings();
              AppTopToast.show(
                context,
                message: 'Reset successfully',
                icon: Icons.refresh_rounded,
                backgroundColor: Colors.green,
              );
              Navigator.of(context).pop();
            },
            child: Text(
              'Reset',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
                          SettingsSectionCard(children: [
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
                          Padding(
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
                          Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Timer',
                            value: settings.timer,
                            items: _timers,
                            onChanged: (v) =>
                                settings.set(() => settings.timer = v!),
                          ),
                          ]),
                        ],
                      ),
                    ),
                    const AdBannerWidget(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        16,
                      ),
                      child: AppPrimaryButton(
                        label: 'Save Changes',
                        icon: Icons.save_outlined,
                        onPressed: () async {
                          await settings.saveCameraSettings();
                          if (!context.mounted) return;
                          AppTopToast.show(
                            context,
                            message: 'Changes saved successfully',
                            icon: Icons.check_circle_outline_rounded,
                            backgroundColor: Colors.green,
                          );
                          Navigator.of(context).pop();
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
