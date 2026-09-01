import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Location & GPS.
///
/// Location source, precision/accuracy toggles, coordinate format,
/// address language, refresh policy, and a live "Test GPS" status card.
class LocationGpsScreen extends StatefulWidget {
  const LocationGpsScreen({super.key});

  @override
  State<LocationGpsScreen> createState() => _LocationGpsScreenState();
}

class _LocationGpsScreenState extends State<LocationGpsScreen> {
  static const _sources = ['Device GPS', 'Network', 'GPS + Network'];
  static const _thresholds = ['±10 m', '±20 m', '±50 m', '±100 m'];
  static const _coordinateFormats = ['Decimal Degrees', 'DMS'];
  static const _languages = ['English', 'Tamil', 'Hindi', 'Spanish'];
  static const _refreshOptions = ['Every capture', 'Every 30s', 'Manual'];

  bool _testing = false;

  Future<void> _testGps() async {
    setState(() => _testing = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Location & GPS'),
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
                          DropdownSettingRow<String>(
                            title: 'Location source',
                            value: settings.locationSource,
                            items: _sources,
                            onChanged: (v) =>
                                settings.set(() => settings.locationSource = v!),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          ToggleSettingRow(
                            title: 'Precise Location',
                            value: settings.preciseLocation,
                            onChanged: (v) =>
                                settings.set(() => settings.preciseLocation = v),
                          ),
                          ToggleSettingRow(
                            title: 'High Accuracy Mode',
                            value: settings.highAccuracyMode,
                            onChanged: (v) =>
                                settings.set(() => settings.highAccuracyMode = v),
                          ),

                          DropdownSettingRow<String>(
                            title: 'GPS Accuracy Threshold',
                            value: settings.gpsAccuracyThreshold,
                            items: _thresholds,
                            onChanged: (v) =>
                                settings.set(() => settings.gpsAccuracyThreshold = v!),
                          ),

                          ToggleSettingRow(
                            title: 'Wait for accurate signal',
                            value: settings.waitForAccurateSignal,
                            onChanged: (v) =>
                                settings.set(() => settings.waitForAccurateSignal = v),
                          ),
                          ToggleSettingRow(
                            title: 'Show accuracy warning',
                            value: settings.showAccuracyWarning,
                            onChanged: (v) =>
                                settings.set(() => settings.showAccuracyWarning = v),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          Text(
                            'Stamp location details',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ToggleSettingRow(
                            title: 'Show GPS accuracy on stamp',
                            value: settings.showAccuracy,
                            onChanged: (v) =>
                                settings.set(() => settings.showAccuracy = v),
                          ),
                          ToggleSettingRow(
                            title: 'Show altitude on stamp',
                            value: settings.showAltitude,
                            onChanged: (v) =>
                                settings.set(() => settings.showAltitude = v),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          DropdownSettingRow<String>(
                            title: 'Coordinate Format',
                            value: settings.coordinateFormat,
                            items: _coordinateFormats,
                            onChanged: (v) =>
                                settings.set(() => settings.coordinateFormat = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Address Language',
                            value: settings.addressLanguage,
                            items: _languages,
                            onChanged: (v) =>
                                settings.set(() => settings.addressLanguage = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Refresh location',
                            value: settings.refreshLocation,
                            items: _refreshOptions,
                            onChanged: (v) =>
                                settings.set(() => settings.refreshLocation = v!),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed_rounded,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const GpsStatusBadge(
                                        label: 'GPS Signal Excellent • ±4 m',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last checked: ${_testing ? 'checking…' : 'Just now'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
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
                      child: AppPrimaryButton(
                        label: 'Test GPS',
                        icon: Icons.gps_fixed_rounded,
                        isLoading: _testing,
                        onPressed: _testGps,
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
