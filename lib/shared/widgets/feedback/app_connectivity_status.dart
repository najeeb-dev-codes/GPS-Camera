import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import 'app_top_toast.dart';

/// Shows an offline badge and announces when internet access is restored.
class AppConnectivityStatus extends StatefulWidget {
  const AppConnectivityStatus({super.key});

  @override
  State<AppConnectivityStatus> createState() =>
      _AppConnectivityStatusState();
}

class _AppConnectivityStatusState extends State<AppConnectivityStatus> {
  StreamSubscription<bool>? _internetSubscription;
  bool? _hasInternet;

  @override
  void initState() {
    super.initState();

    final connectivity = ConnectivityService.instance;
    _hasInternet = connectivity.lastKnownInternetAccess;
    connectivity.start();
    _internetSubscription = connectivity.onInternetStatusChanged.listen(
      _handleInternetStatusChanged,
    );
  }

  void _handleInternetStatusChanged(bool hasInternet) {
    if (!mounted || _hasInternet == hasInternet) return;

    final wasOffline = _hasInternet == false;
    setState(() => _hasInternet = hasInternet);

    if (!hasInternet || !wasOffline) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      AppTopToast.show(
        context,
        message: 'Internet connection restored.',
        icon: Icons.wifi_rounded,
      );
    });
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInternet != false) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: AppTypography.tiny.copyWith(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
