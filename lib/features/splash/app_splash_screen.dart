import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Branded Flutter splash shown after Android's mandatory launch transition.
/// The existing permission and startup routing remains owned by [nextScreen].
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    required this.nextScreen,
    this.autoTransition = true,
    super.key,
  });

  final Widget nextScreen;

  /// Set false when keeping the branded splash visible while startup work finishes.
  final bool autoTransition;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  Timer? _transitionTimer;
  bool _showNextScreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoTransition) {
      _transitionTimer = Timer(const Duration(milliseconds: 4000), () {
        if (!mounted) return;
        setState(() => _showNextScreen = true);
      });
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showNextScreen) return widget.nextScreen;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icon/app_icon.png',
                            width: 190,
                            height: 190,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.location_on,
                              size: 150,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Capture proof\nwith place & time',
                            textAlign: TextAlign.center,
                            style: AppTypography.display.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add verified location, time and details to your photos.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
