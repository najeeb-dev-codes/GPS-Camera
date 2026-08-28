import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Settings > About & Help.
///
/// App logo, version, "check for updates" state, and a list of help /
/// legal links (Help Center, How to Use, Report a Problem, Send Feedback,
/// Rate the App, Terms, Privacy Policy, Open-source Licenses).
class AboutHelpScreen extends StatefulWidget {
  const AboutHelpScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  State<AboutHelpScreen> createState() => _AboutHelpScreenState();
}

class _AboutHelpScreenState extends State<AboutHelpScreen> {
  bool _checking = false;
  bool _upToDate = true;

  Future<void> _checkForUpdates() async {
    setState(() {
      _checking = true;
      _upToDate = false;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _upToDate = true;
    });
  }

  void _openLink(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $label...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'About & Help'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 600 ? 48.0 : AppSpacing.screenPadding;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                24,
              ),
              children: [
                Center(
                  child: Column(
                    children: [
                      const AppLogoMark(size: 88),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'GeoStamp Camera',
                        style: AppTypography.h1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version ${AboutHelpScreen.appVersion}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture proof with place & time.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                SettingsListTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => _openLink('Help Center'),
                ),
                SettingsListTile(
                  icon: Icons.menu_book_outlined,
                  title: 'How to Use',
                  onTap: () => _openLink('How to Use'),
                ),
                SettingsListTile(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: 'Report a Problem',
                  onTap: () => _openLink('Report a Problem'),
                ),
                SettingsListTile(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  onTap: () => _openLink('Send Feedback'),
                ),
                SettingsListTile(
                  icon: Icons.star_border_rounded,
                  title: 'Rate the App',
                  onTap: () => _openLink('Rate the App'),
                ),
                SettingsListTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _openLink('Terms of Service'),
                ),
                SettingsListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _openLink('Privacy Policy'),
                ),
                SettingsListTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Open-source Licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'GeoStamp Camera',
                    applicationVersion: AboutHelpScreen.appVersion,
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1, color: AppColors.border),
                ),

                InkWell(
                  onTap: _checking ? null : _checkForUpdates,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.system_update_outlined,
                          color: AppColors.textSecondary,
                          size: AppSizes.iconMd,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Check for Updates',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        if (_checking)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_upToDate)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success, size: AppSizes.iconSm),
                              const SizedBox(width: 4),
                              Text(
                                "You're up to date",
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
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