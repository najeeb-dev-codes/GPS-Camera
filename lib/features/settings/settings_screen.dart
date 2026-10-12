import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import '../stamp_templates/stamp_templates_screen.dart';
import 'camera_settings_screen.dart';
import 'faq/faq_screen.dart';
import 'file_naming_screen.dart';
import 'howtouse/how_to_use_screen.dart';
import 'notifications_screen.dart';
import 'permissions_settings_screen.dart';
import 'photo_quality_screen.dart';
import 'theme_screen.dart' as theme_page;
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _volumeActions = <String>[
    'Capture',
    'Volume',
    'Zoom',
  ];

  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _setSaveOriginalPhoto(
    BuildContext context,
    AppSettingsService settings,
    bool enabled,
  ) {
    settings.set(() => settings.saveOriginalPhoto = enabled);
    AppTopToast.show(
      context,
      message: enabled
          ? 'Save Original Photo enabled.'
          : 'Save Original Photo disabled.',
      icon: enabled
          ? Icons.photo_library_outlined
          : Icons.hide_image_outlined,
      backgroundColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(
        title: 'Settings',
        showBack: false,
        showConnectivityStatus: true,
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

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.xxl,
                  ),
                  children: [
                    SettingsSectionCard(
                      children: [
                        SettingsListTile(
                          icon: Icons.camera_alt_outlined,
                          title: 'Camera',
                          subtitle: 'Aspect ratio, grid, focus and timer',
                          onTap: () => _push(
                            context,
                            const CameraSettingsScreen(),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.volume_up_outlined,
                              size: AppSizes.iconMd,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(
                              width: AppSpacing.md,
                            ),
                            Expanded(
                              child: DropdownSettingRow<String>(
                                title: 'Volume Key Action',
                                value: settings.volumeKeyAction,
                                items: _volumeActions,
                                onChanged: (value) {
                                  if (value == null) return;

                                  settings.set(
                                    () => settings.volumeKeyAction = value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SettingsListTile(
                          icon: Icons.photo_outlined,
                          title: 'Save Original Photo',
                          trailing: AppToggle(
                            value: settings.saveOriginalPhoto,
                            onChanged: (value) => _setSaveOriginalPhoto(
                              context,
                              settings,
                              value,
                            ),
                          ),
                          onTap: () => _setSaveOriginalPhoto(
                            context,
                            settings,
                            !settings.saveOriginalPhoto,
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.dashboard_customize_outlined,
                          title: 'Stamp Template',
                          subtitle: 'Choose and customize a stamp',
                          onTap: () => _push(
                            context,
                            const StampTemplatesScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.high_quality_outlined,
                          title: 'Photo Quality',
                          subtitle: 'Resolution and compression',
                          onTap: () => _push(
                            context,
                            const PhotoQualityScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.drive_file_rename_outline,
                          title: 'File Name Format',
                          subtitle: 'File label and numbering pattern',
                          onTap: () => _push(
                            context,
                            const FileNamingScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: settings.masterNotifications ? 'On' : 'Off',
                          onTap: () => _push(
                            context,
                            const NotificationsScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Permissions',
                          subtitle:
                              'Camera, location, gallery and notifications',
                          onTap: () => _push(
                            context,
                            const PermissionSettingsScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SettingsHeading(title: 'Theme'),
                    const SizedBox(height: AppSpacing.xs),
                    SettingsSectionCard(
                      padding: EdgeInsets.zero,
                      children: [
                        _SettingsThemeOption(
                          title: 'Light',
                          icon: Icons.light_mode_outlined,
                          value: ThemeMode.light,
                          selectedValue: settings.themeMode,
                          onChanged: settings.setThemeMode,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        _SettingsThemeOption(
                          title: 'Dark',
                          icon: Icons.dark_mode_outlined,
                          value: ThemeMode.dark,
                          selectedValue: settings.themeMode,
                          onChanged: settings.setThemeMode,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        _SettingsThemeOption(
                          title: 'System',
                          subtitle: 'Follow your device theme',
                          icon: Icons.settings_suggest_outlined,
                          value: ThemeMode.system,
                          selectedValue: settings.themeMode,
                          onChanged: settings.setThemeMode,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        _AppColourSettingRow(
                          color: settings.accentColor,
                          onTap: () => _push(
                            context,
                            const theme_page.ThemeScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SettingsHeading(
                      title: 'Help & Support',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SettingsSectionCard(
                      children: [
                        SettingsListTile(
                          icon: Icons.menu_book_outlined,
                          title: 'How to Use',
                          onTap: () => _push(
                            context,
                            const HowToUseScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.help_outline,
                          title: 'FAQ',
                          onTap: () => _push(
                            context,
                            const FaqScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SettingsHeading(title: 'About'),
                    const SizedBox(height: AppSpacing.xs),
                    SettingsSectionCard(
                      children: [
                        SettingsListTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => _push(
                            context,
                            const PrivacyPolicyScreen(),
                          ),
                        ),
                        SettingsListTile(
                          icon: Icons.info_outline,
                          title: 'App Version',
                          trailing: FutureBuilder<PackageInfo>(
                            future: _packageInfo,
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data?.version ?? '—',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        '@2026 copyright Raiyaan Infotecct. All rights reserved',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
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
        onTap: (index) {
          AppNavigator.handleBottomNavTap(
            context,
            index,
          );
        },
      ),
    );
  }
}

class _AppColourSettingRow extends StatelessWidget {
  const _AppColourSettingRow({
    required this.color,
    required this.onTap,
  });

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'App Colour',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 64,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: AppSizes.iconMd,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'App Colour',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),

                // The 48x48 space matches the Radio widget's
                // default layout width and keeps both controls
                // in exactly the same column.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsThemeOption extends StatelessWidget {
  const _SettingsThemeOption({
    required this.title,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode selectedValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = value == selectedValue;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title theme',
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconMd,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(
                        height: AppSpacing.xxs,
                      ),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Radio<ThemeMode>(
                value: value,
                groupValue: selectedValue,
                onChanged: (mode) {
                  if (mode != null) {
                    onChanged(mode);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.caption.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
