import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../feedback/app_connectivity_status.dart';

/// Standard top bar: optional back arrow, title, optional trailing actions.
///
/// Covers screens like Permissions, Capture Preview, Gallery, Photo Details,
/// Settings, Projects, Templates.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.leadingIcon,
    this.onLeadingTap,
    this.backgroundColor,
    this.foregroundColor,
    this.showConnectivityStatus = false,
  });

  final String title;

  /// Show a back arrow instead of a custom [leadingIcon] (e.g. Home's
  /// hamburger menu).
  final bool showBack;
  final VoidCallback? onBack;

  /// Trailing icon buttons (e.g. notification bell, search, filter, more).
  final List<Widget> actions;

  /// Custom leading icon when [showBack] is false (e.g. Icons.menu).
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;

  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Places the offline badge after the trailing action icons.
  final bool showConnectivityStatus;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? colors.onSurface;

    return AppBar(
      backgroundColor: backgroundColor ?? colors.surface,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: fg),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : (leadingIcon != null
              ? IconButton(
                  icon: Icon(leadingIcon, color: fg),
                  onPressed: onLeadingTap,
                )
              : null),
      title: Text(
        title,
        style: AppTypography.h3.copyWith(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        ...actions,
        if (showConnectivityStatus) const AppConnectivityStatus(),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
