import 'package:flutter/material.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > Theme (labelled "Appearance" in the mockup).
///
/// Theme mode (Light/Dark/System), accent color, font/layout options,
/// and a map style + live preview card.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  static const _fonts = ['Default', 'Rounded', 'Classic'];
  static const _fontSizes = ['Small', 'Medium', 'Large'];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Appearance'),
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
                            'Theme',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTabSelector(
                            tabs: const ['Light', 'Dark', 'System'],
                            scrollable: false,
                            selectedIndex: switch (settings.themeMode) {
                              ThemeMode.light => 0,
                              ThemeMode.dark => 1,
                              ThemeMode.system => 2,
                            },
                            onChanged: (i) => settings.set(() {
                              settings.themeMode =
                                  [ThemeMode.light, ThemeMode.dark, ThemeMode.system][i];
                            }),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Accent Color',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ColorSwatchPicker(
                            colors: AppSettingsService.accentColors,
                            selectedIndex: settings.accentColorIndex,
                            onChanged: (i) =>
                                settings.set(() => settings.accentColorIndex = i),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          DropdownSettingRow<String>(
                            title: 'App Font',
                            value: settings.appFont,
                            items: _fonts,
                            onChanged: (v) => settings.set(() => settings.appFont = v!),
                          ),
                          DropdownSettingRow<String>(
                            title: 'Font Size',
                            value: settings.fontSize,
                            items: _fontSizes,
                            onChanged: (v) => settings.set(() => settings.fontSize = v!),
                          ),
                          ToggleSettingRow(
                            title: 'Compact Layout',
                            value: settings.compactLayout,
                            onChanged: (v) => settings.set(() => settings.compactLayout = v),
                          ),
                          ToggleSettingRow(
                            title: 'High Contrast',
                            value: settings.highContrast,
                            onChanged: (v) => settings.set(() => settings.highContrast = v),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Divider(height: 1, color: AppColors.border),
                          ),

                          Text(
                            'Map Style Preview',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            height: 56,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: AppSettingsService.mapStyles.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final selected = index == settings.mapStylePreviewIndex;
                                return GestureDetector(
                                  onTap: () => settings
                                      .set(() => settings.mapStylePreviewIndex = index),
                                  child: Container(
                                    width: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.neutral200,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: selected
                                            ? settings.accentColor
                                            : AppColors.border,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: const Icon(Icons.map_outlined, size: 20),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Live Preview',
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: GpsStampOverlay(
                              dark: false,
                              data: const GpsStampData(
                                address: 'Tirunelveli, Tamil Nadu',
                                coordinates: '8.7281° N, 77.7081° E',
                                dateTime: '18 Aug 2026 • 04:25 PM',
                                weather: '28°C',
                                pressure: '1021 hPa',
                                altitude: '16 m',
                              ),
                              mapThumbnail: const MapPreviewThumbnail(size: 44),
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
                        label: 'Apply Appearance',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appearance applied')),
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