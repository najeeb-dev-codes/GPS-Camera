import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 9 — Notifications.
///
/// Notifications are a *recommended*, non-blocking permission: whatever the
/// user picks here, the flow always continues to [PermissionFlowService]'s
/// final check (Permissions Enabled / Permission Required), it never gates
/// on this screen.
class NotificationAccessScreen extends StatefulWidget {
  const NotificationAccessScreen({
    super.key,
    this.onFinished,
  });

  final VoidCallback? onFinished;

  @override
  State<NotificationAccessScreen> createState() =>
      _NotificationAccessScreenState();
}

class _NotificationAccessScreenState extends State<NotificationAccessScreen> {
  bool _isRequesting = false;

  bool _photoCaptureAlerts = true;
  bool _gpsAccuracyAlerts = true;
  bool _backupSyncAlerts = true;

  // ---------------------------------------------------------------------------
  // ALLOW NOTIFICATIONS
  // ---------------------------------------------------------------------------

  Future<void> _allowNotifications() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final currentStatus = await Permission.notification.status;

      if (!currentStatus.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {
      // Notifications never block onboarding — fall through regardless.
    }

    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

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
      backgroundColor: AppColors.background,

      appBar: AppTopBar(
        title: '',
        onBack: _maybeLater,
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
                        // -----------------------------------------------------
                        // BELL ICON
                        // -----------------------------------------------------

                        Container(
                          width: width >= 600 ? 92 : 78,
                          height: width >= 600 ? 92 : 78,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E7FF),
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
                            'Get useful alerts when a photo is saved, GPS '
                            'accuracy is low, or cloud backup completes.',
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
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.warning,
                          title: 'GPS signal accuracy is ±18 m',
                          subtitle: 'Accuracy may vary in this area.',
                        ),

                        const SizedBox(height: 10),

                        _buildSampleNotification(
                          icon: Icons.cloud_done_rounded,
                          iconColor: AppColors.primary,
                          title: 'Backup completed',
                          subtitle: 'Your photos are safely backed up.',
                        ),

                        const SizedBox(height: 20),

                        // -----------------------------------------------------
                        // RECOMMENDED CATEGORIES
                        // -----------------------------------------------------

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recommended notification categories',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        ToggleSettingRow(
                          icon: Icons.photo_camera_outlined,
                          title: 'Photo & Capture Alerts',
                          value: _photoCaptureAlerts,
                          onChanged: (value) {
                            setState(() {
                              _photoCaptureAlerts = value;
                            });
                          },
                        ),

                        ToggleSettingRow(
                          icon: Icons.gps_fixed_rounded,
                          title: 'GPS Accuracy Alerts',
                          value: _gpsAccuracyAlerts,
                          onChanged: (value) {
                            setState(() {
                              _gpsAccuracyAlerts = value;
                            });
                          },
                        ),

                        ToggleSettingRow(
                          icon: Icons.backup_rounded,
                          title: 'Backup & Sync Alerts',
                          value: _backupSyncAlerts,
                          onChanged: (value) {
                            setState(() {
                              _backupSyncAlerts = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // -------------------------------------------------------------
                // BOTTOM ACTIONS
                // -------------------------------------------------------------

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    children: [
                      AppPrimaryButton(
                        label: 'Allow Notifications',
                        isLoading: _isRequesting,
                        onPressed: _allowNotifications,
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _isRequesting ? null : _maybeLater,
                        child: Text(
                          'Maybe Later',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
        color: AppColors.white,
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
}
