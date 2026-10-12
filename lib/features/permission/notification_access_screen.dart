import 'package:flutter/material.dart';

import '../../core/constants/app_brand.dart';
import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'permission_ad_gate.dart';
import 'permission_recovery_dialog.dart';

/// Screen 9 — Notifications.
///
/// Notifications are a *recommended*, non-blocking permission: whatever the
/// user picks here, the flow always continues to [PermissionFlowService]'s
/// final check (Permissions Enabled / Permission Required), it never gates
/// on this screen.
class NotificationAccessScreen extends StatefulWidget {
  const NotificationAccessScreen({
    super.key,
    this.requestOnOpen = false,
    this.onAutomaticFinished,
    this.onFinished,
  });

  final bool requestOnOpen;
  final VoidCallback? onAutomaticFinished;
  final VoidCallback? onFinished;

  @override
  State<NotificationAccessScreen> createState() =>
      _NotificationAccessScreenState();
}

class _NotificationAccessScreenState extends State<NotificationAccessScreen> {
  bool _isRequesting = false;
  bool _automaticRequestFinished = false;

  void _finishAutomaticRequest() {
    if (!widget.requestOnOpen ||
        !mounted ||
        _automaticRequestFinished) {
      return;
    }

    _automaticRequestFinished = true;
    final onFinished = widget.onAutomaticFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // ALLOW NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<void> _allowNotifications() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      if (!await PermissionFlowService.isNotificationGranted()) {
        final needsWarning =
            await PermissionFlowService.shouldShowRequestWarning(
          ManagedAppPermission.notifications,
        );
        if (needsWarning && mounted) {
          await PermissionRecoveryDialog.showRepeatDenialToast(
            context,
            const [ManagedAppPermission.notifications],
          );
        }

        await PermissionFlowService.requestPermission(
          ManagedAppPermission.notifications,
        );
      }
    } catch (_) {
      // Notifications never block onboarding — fall through regardless.
    }

    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    if (widget.requestOnOpen) {
      _finishAutomaticRequest();
      return;
    }

    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    await PermissionFlowService.advance(
      context,
      from: PermissionStep.notifications,
    );
  }

  // ---------------------------------------------------------------------------
  // MAYBE LATER
  // ---------------------------------------------------------------------------

  Future<void> _maybeLater() async {
    if (_isRequesting) return;

    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    await PermissionFlowService.advance(
      context,
      from: PermissionStep.notifications,
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppTopBar(
        title: '',
        showBack: !widget.requestOnOpen,
        onBack: () => Navigator.of(context).pop(),
      ),

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding =
                width >= 600 ? 48.0 : AppSpacing.screenPadding;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      children: [
                        if (widget.requestOnOpen) ...[
                          PermissionAdGate(
                            onReady: () {
                              _allowNotifications();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        // -----------------------------------------------------
                        // BELL ICON
                        // -----------------------------------------------------

                        Container(
                          width: width >= 600 ? 92 : 78,
                          height: width >= 600 ? 92 : 78,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.notifications_rounded,
                            size: width >= 600 ? 56 : 46,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // HEADING
                        // -----------------------------------------------------

                        Text(
                          'Stay informed',
                          textAlign: TextAlign.center,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // -----------------------------------------------------
                        // DESCRIPTION
                        // -----------------------------------------------------

                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Text(
                            'Notification permission keeps you updated about '
                            'important activity in ${AppBrand.name}.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // -----------------------------------------------------
                        // SAMPLE NOTIFICATIONS
                        // -----------------------------------------------------

                        _buildSampleNotification(
                          icon: Icons.check_circle,
                          iconColor: AppColors.success,
                          title: 'Photo saved successfully',
                          subtitle: 'Your photo is saved with GPS details.',
                        ),

                        const SizedBox(height: 10),

                        _buildSampleNotification(
                          icon: Icons.folder_outlined,
                          iconColor: AppColors.primary,
                          title: 'Project created successfully',
                          subtitle: 'Your new project is ready to use.',
                        ),

                        const SizedBox(height: 10),

                        _buildSampleNotification(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.primary,
                          title: AppBrand.name,
                          subtitle: 'You have a new app notification.',
                        ),

                        const SizedBox(height: 20),
                        _buildPrivacyCard(),
                        const SizedBox(height: 14),
                        _buildNotificationPoints(),
                        if (!widget.requestOnOpen) ...[
                          const SizedBox(height: 20),
                          const AdBannerWidget(
                            format: AdDisplayFormat.mediumRectangle,
                            reserveSpaceWhileLoading: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAMPLE NOTIFICATION ROW
  // ---------------------------------------------------------------------------

  Widget _buildSampleNotification({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notifications are optional and can be changed anytime in Settings.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recommended',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPoints() {
    const points = [
      'Confirms when a captured photo is saved successfully.',
      'Confirms when a new project is created successfully.',
      'Shows scheduled or custom app notifications.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications you may receive',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final point in points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (point != points.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
