import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

enum InternetRequiredAction { cancel, connected, openSettings }

Future<InternetRequiredAction> showInternetRequiredDialog(
  BuildContext context,
) async {
  return await showDialog<InternetRequiredAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const InternetRequiredDialog(),
      ) ??
      InternetRequiredAction.cancel;
}

class InternetRequiredDialog extends StatefulWidget {
  const InternetRequiredDialog({super.key});

  @override
  State<InternetRequiredDialog> createState() =>
      _InternetRequiredDialogState();
}

class _InternetRequiredDialogState extends State<InternetRequiredDialog> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _checkingConnection = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription =
        ConnectivityService.instance.onBackOnline.listen((_) {
      unawaited(_closeWhenConnected());
    });
  }

  Future<void> _closeWhenConnected() async {
    if (_checkingConnection || !mounted) return;
    _checkingConnection = true;

    final online = await ConnectivityService.instance.hasInternetAccess();
    if (!mounted) return;

    _checkingConnection = false;
    if (online) {
      Navigator.of(context).pop(InternetRequiredAction.connected);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Internet connection required',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Connect to Wi-Fi or turn on mobile data to open '
                  'the camera.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(shape: shape),
                    onPressed: () => Navigator.of(context).pop(
                      InternetRequiredAction.openSettings,
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Turn On Internet'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: shape),
                    onPressed: () => Navigator.of(context).pop(
                      InternetRequiredAction.cancel,
                    ),
                    child: const Text('Cancel'),
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
