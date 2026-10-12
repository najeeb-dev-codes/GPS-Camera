import 'package:flutter/material.dart';

import '../../core/services/permission_flow_service.dart';
import '../../core/theme/app_colors.dart';

/// Shared denial recovery UI used by onboarding, recovery and Settings.
class PermissionRecoveryDialog {
  PermissionRecoveryDialog._();

  static String nameOf(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => 'Camera',
      ManagedAppPermission.location => 'Location',
      ManagedAppPermission.gallery => 'Gallery',
      ManagedAppPermission.notifications => 'Notifications',
    };
  }

  static IconData iconOf(ManagedAppPermission permission) {
    return switch (permission) {
      ManagedAppPermission.camera => Icons.camera_alt_outlined,
      ManagedAppPermission.location => Icons.location_on_outlined,
      ManagedAppPermission.gallery => Icons.photo_library_outlined,
      ManagedAppPermission.notifications => Icons.notifications_outlined,
    };
  }

  static Future<void> showRepeatDenialToast(
    BuildContext context,
    List<ManagedAppPermission> permissions,
  ) async {
    if (permissions.isEmpty) return;

    final names = permissions.map(nameOf).join(', ');
    final required = permissions.any(
      PermissionFlowService.requiredPermissions.contains,
    );
    final isSingle = permissions.length == 1;
    final message = required
        ? '$names ${isSingle ? 'permission is' : 'permissions are'} required '
            'for the app. If you deny ${isSingle ? 'it' : 'them'} again, '
            'you must grant ${isSingle ? 'it' : 'them'} through App Settings.'
        : '$names ${isSingle ? 'permission was' : 'permissions were'} denied '
            'earlier. If you deny ${isSingle ? 'it' : 'them'} again, '
            'you must grant ${isSingle ? 'it' : 'them'} through App Settings.';

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (overlayContext) {
        final width = MediaQuery.sizeOf(overlayContext).width;
        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width >= 600 ? 440 : width - 32,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B21B6),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      // The next OS permission dialog opens after the warning has remained
      // visible at the top of the screen for two seconds.
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      entry.remove();
      entry.dispose();
    }
  }

  static Future<void> showBlockedPermissions(
    BuildContext context,
    List<ManagedAppPermission> permissions,
  ) async {
    if (permissions.isEmpty) return;

    final openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Enable permissions in App Settings'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Android is no longer showing the OS permission dialog '
                      'for the following access:',
                    ),
                    const SizedBox(height: 12),
                    for (final permission in permissions) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              iconOf(permission),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                nameOf(permission),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Text(
                              'Blocked',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'To enable: App Settings → Permissions → select each '
                      'permission shown above → Allow.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open App Settings'),
              ),
            ],
          ),
        ) ??
        false;

    if (openSettings) {
      await PermissionFlowService.openSystemSettings();
    }
  }
}
