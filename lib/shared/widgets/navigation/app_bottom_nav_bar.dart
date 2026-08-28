import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Bottom navigation bar: Home / Gallery / Camera (raised FAB) / Projects /
/// Settings — matches the tab bar on Home, Gallery, Projects, Settings.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// 0 = Home, 1 = Gallery, 2 = Camera, 3 = Projects, 4 = Settings.
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library,
      label: 'Gallery',
    ),
    (icon: Icons.camera_alt, activeIcon: Icons.camera_alt, label: ''),
    (
      icon: Icons.folder_copy_outlined,
      activeIcon: Icons.folder_copy,
      label: 'Projects',
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = currentIndex == index;

            // Center camera slot renders as a raised circular FAB.
            if (index == 2) {
              return _CameraFab(
                icon: item.icon,
                selected: selected,
                onTap: () => onTap(index),
              );
            }

            return _NavItem(
              icon: selected ? item.activeIcon : item.icon,
              label: item.label,
              selected: selected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.neutral400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconMd),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.tiny.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFab extends StatelessWidget {
  const _CameraFab({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Icon(Icons.camera_alt, color: AppColors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
