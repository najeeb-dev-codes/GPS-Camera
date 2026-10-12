import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > About & Help.
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  static const String appVersion = '1.0.0';

  void _showComingSoon(
    BuildContext context, {
    required String featureName,
    required IconData icon,
  }) {
    ComingSoonDialog.show(
      context,
      featureName: featureName,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'About & Help'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              children: [
                Center(
                  child: Column(
                    children: [
                      const AppLogoMark(size: 88),
                      const SizedBox(height: AppSpacing.md),
                      Text(AppBrand.name, style: AppTypography.h1),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Version ${AboutHelpScreen.appVersion}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Capture proof with place & time.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsSectionCard(
                  children: [
                    _AboutFeatureTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Help Center',
                        icon: Icons.help_outline,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.menu_book_outlined,
                      title: 'How to Use',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'How to Use',
                        icon: Icons.menu_book_outlined,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.report_gmailerrorred_outlined,
                      title: 'Report a Problem',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Report a Problem',
                        icon: Icons.report_gmailerrorred_outlined,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.feedback_outlined,
                      title: 'Send Feedback',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Send Feedback',
                        icon: Icons.feedback_outlined,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.star_border_rounded,
                      title: 'Rate the App',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Rate the App',
                        icon: Icons.star_border_rounded,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Terms of Service',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                      ),
                    ),
                    _AboutFeatureTile(
                      icon: Icons.system_update_outlined,
                      title: 'Check for Updates',
                      showDivider: false,
                      onTap: () => _showComingSoon(
                        context,
                        featureName: 'Check for Updates',
                        icon: Icons.system_update_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Made with care for field teams and travelers.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AboutFeatureTile extends StatelessWidget {
  const _AboutFeatureTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsListTile(
          icon: icon,
          title: title,
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }
}
