import 'package:flutter/material.dart';

import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 1 — Welcome.
///
/// Matches the mockup exactly: white background, everything centered —
/// logo circle, headline, description — with "Get Started" pinned to the
/// bottom.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onGetStarted,
  });

  final VoidCallback? onGetStarted;

  static const _headline = 'Capture proof\nwith place & time';

  static const _description =
      'Add verified location, time and details to your photos.';

  static const _ctaLabel = 'Get Started';

  /// If the caller didn't provide its own [onGetStarted] (e.g. this screen
  /// is the app's actual entry point rather than being driven by an
  /// external router), fall back to the permission flow's own entry point:
  /// straight to Home if every required permission is already granted,
  /// otherwise into the Permission Center.
  Future<void> _handleGetStarted(BuildContext context) async {
    if (onGetStarted != null) {
      onGetStarted!();
      return;
    }

    await PermissionFlowService.startFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
          ),
          child: Column(
            children: [
              // ------------------------------------------------------------
              // TOP CONTENT
              // ------------------------------------------------------------
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // GPS Mark app icon
                    Image.asset(
                      'assets/icon/app_icon_png.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    // Heading
                    Text(
                      _headline,
                      textAlign: TextAlign.center,
                      style: AppTypography.display,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // Description
                    Text(
                      _description,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------------------
              // BOTTOM BUTTON
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppPrimaryButton(
                      label: _ctaLabel,
                      onPressed: () => _handleGetStarted(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Powered by Raiyaan Infotech',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '© 2026 Raiyaan Infotech. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
