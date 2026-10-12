import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_update_info.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Non-dismissible dialog used only when the backend explicitly requires an
/// update. Its content comes from the app-version API.
class ForceUpdateDialog extends StatefulWidget {
  const ForceUpdateDialog({
    required this.updateInfo,
    super.key,
  });

  final AppUpdateInfo updateInfo;

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _openingStore = false;
  String? _storeError;

  Future<void> _openStore() async {
    if (_openingStore) return;

    final storeUrl = widget.updateInfo.storeUrl.trim();
    if (storeUrl.isEmpty) {
      setState(() {
        _storeError = 'The update link is currently unavailable.';
      });
      return;
    }

    setState(() {
      _openingStore = true;
      _storeError = null;
    });

    try {
      final opened = await launchUrl(
        Uri.parse(storeUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        setState(() {
          _storeError = 'Unable to open the app store. Please try again.';
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _storeError = 'Unable to open the app store. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _openingStore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = screenWidth < 360 ? 16.0 : 24.0;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: AppSpacing.xxl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    size: 32,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.updateInfo.updateTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.updateInfo.updateMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (widget.updateInfo.currentVersion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Latest version: ${widget.updateInfo.currentVersion}',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_storeError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _storeError!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: _openingStore ? null : _openStore,
                    icon: _openingStore
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.open_in_new_rounded),
                    label: Text(
                      _openingStore ? 'Opening Store...' : 'Update Now',
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
