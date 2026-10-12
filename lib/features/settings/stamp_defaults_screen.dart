import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Stamp Defaults.
///
/// Live stamp preview, template & map type, the "Visible fields" checkbox
/// grid, stamp position, and default size / opacity sliders.
class StampDefaultsScreen extends StatelessWidget {
  const StampDefaultsScreen({super.key});

  static const _templates = ['Map Card', 'Classic', 'Minimal', 'Badge'];
  static const _mapTypes = ['Standard', 'Satellite', 'Terrain'];
  static const _positions = [
    'Bottom Right',
    'Bottom Left',
    'Top Right',
    'Top Left',
    'Center',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Stamp Defaults'),
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
                            'Stamp Preview',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // -------------------------------------------
                          // PREVIEW
                          // -------------------------------------------
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF8B8FA3),
                                          Color(0xFF4A4E63),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.construction_rounded,
                                      color: Colors.white24,
                                      size: 64,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: AppSpacing.sm,
                                  right: AppSpacing.sm,
                                  bottom: AppSpacing.sm,
                                  child: Opacity(
                                    opacity: settings.stampOpacity / 100,
                                    child: GpsStampOverlay(
                                      data: const GpsStampData(
                                        address: 'Tirunelveli, Tamil Nadu, India',
                                        coordinates: '8.7281° N, 77.7081° E',
                                        dateTime: '18 Aug 2026 • 04:25 PM',
                                        weather: '28°C',
                                        pressure: '1021 hPa',
                                        altitude: '16 m',
                                      ),
                                      visibility: GpsStampFieldVisibility(
                                        address: settings.showAddress,
                                        coordinates: settings.showCoordinates,
                                        dateTime: settings.showDateTime,
                                        weather: settings.showWeather,
                                        compass: settings.showCompass,
                                        altitude: settings.showAltitude,
                                        accuracy: settings.showAccuracy,
                                        note: settings.showNote,
                                        logo: settings.showLogo,
                                      ),
                                      mapThumbnail: const MapPreviewThumbnail(size: 40),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          DropdownSettingRow<String>(
                            title: 'Template',
                            value: settings.stampTemplate,
                            items: _templates,
                            onChanged: (v) =>
                                settings.set(() => settings.stampTemplate = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Map Type',
                            value: settings.mapType,
                            items: _mapTypes,
                            onChanged: (v) => settings.set(() => settings.mapType = v!),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          Text(
                            'Visible fields',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          _FieldCheckboxGrid(settings: settings),

                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          DropdownSettingRow<String>(
                            title: 'Stamp Position',
                            value: settings.stampPosition,
                            items: _positions,
                            onChanged: (v) =>
                                settings.set(() => settings.stampPosition = v!),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          AppSlider(
                            label: 'Default Size',
                            value: settings.stampDefaultSize,
                            onChanged: (v) =>
                                settings.set(() => settings.stampDefaultSize = v),
                          ),
                          AppSlider(
                            label: 'Opacity',
                            value: settings.stampOpacity,
                            onChanged: (v) =>
                                settings.set(() => settings.stampOpacity = v),
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
                        label: 'Customize Default Stamp',
                        icon: Icons.edit_outlined,
                        onPressed: () {
                          AppTopToast.show(
                            context,
                            message: 'Opening stamp customization...',
                            icon: Icons.info_outline_rounded,
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

/// Two-column grid of "Visible fields" checkboxes (Address, Coordinates,
/// Date & Time, Weather, Compass, Altitude, Accuracy, Note, Logo).
class _FieldCheckboxGrid extends StatelessWidget {
  const _FieldCheckboxGrid({required this.settings});

  final AppSettingsService settings;

  @override
  Widget build(BuildContext context) {
    final fields = <String, (bool, ValueChanged<bool?>)>{
      'Address': (
        settings.showAddress,
        (v) => settings.set(() => settings.showAddress = v ?? false)
      ),
      'Coordinates': (
        settings.showCoordinates,
        (v) => settings.set(() => settings.showCoordinates = v ?? false)
      ),
      'Date & Time': (
        settings.showDateTime,
        (v) => settings.set(() => settings.showDateTime = v ?? false)
      ),
      'Weather': (
        settings.showWeather,
        (v) => settings.set(() => settings.showWeather = v ?? false)
      ),
      'Compass': (
        settings.showCompass,
        (v) => settings.set(() => settings.showCompass = v ?? false)
      ),
      'Note': (
        settings.showNote,
        (v) => settings.set(() => settings.showNote = v ?? false)
      ),
      'Logo': (
        settings.showLogo,
        (v) => settings.set(() => settings.showLogo = v ?? false)
      ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 3 : 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 0,
          children: fields.entries.map((entry) {
            final width = (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
            return SizedBox(
              width: width,
              child: CheckboxListTile(
                value: entry.value.$1,
                onChanged: entry.value.$2,
                title: Text(entry.key, style: AppTypography.body),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
