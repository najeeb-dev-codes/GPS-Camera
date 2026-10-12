import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';

/// Reusable surface for grouped rows across every Settings screen.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),border: Border.all(
  color: colors.onSurface.withValues(alpha: 0.8),
  width: 0.5,
),
      ),
      child: Column(children: children),
    );
  }
}
