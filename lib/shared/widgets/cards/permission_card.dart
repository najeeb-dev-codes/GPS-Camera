import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.status,
    this.statusColor,
    this.accessLabel,
    this.accessLabelColor,
    this.showArrow = false,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  final String? status;
  final Color? statusColor;

  /// Classification shown before the current permission status.
  /// For example: Required or Recommended.
  final String? accessLabel;
  final Color? accessLabelColor;

  final bool showArrow;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final effectiveStatusColor = statusColor ?? AppColors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 25,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (accessLabel != null || status != null) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // if (accessLabel != null)
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 7,
                        //       vertical: 3,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: (accessLabelColor ?? AppColors.error)
                        //           .withValues(alpha: 0.10),
                        //       borderRadius: BorderRadius.circular(6),
                        //       border: Border.all(
                        //         color: (accessLabelColor ?? AppColors.error)
                        //             .withValues(alpha: 0.35),
                        //       ),
                        //     ),
                        //     child: Text(
                        //       accessLabel!,
                        //       style: AppTypography.caption.copyWith(
                        //         color: accessLabelColor ?? AppColors.error,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ),

                        // if (accessLabel != null) ...[
                        //   const SizedBox(height: 5),
                        //   Container(
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 7,
                        //       vertical: 3,
                        //     ),
                        //     decoration: BoxDecoration(
                        //       color: (accessLabelColor ?? AppColors.error)
                        //           .withValues(alpha: 0.10),
                        //       borderRadius: BorderRadius.circular(6),
                        //       border: Border.all(
                        //         color: (accessLabelColor ?? AppColors.error)
                        //             .withValues(alpha: 0.35),
                        //       ),
                        //     ),
                        //     child: Text(
                        //       accessLabel!,
                        //       style: AppTypography.caption.copyWith(
                        //         color: accessLabelColor ?? AppColors.error,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ),
                        // ],
                        if (accessLabel != null) ...[
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (accessLabelColor ?? AppColors.error)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (accessLabelColor ?? AppColors.error)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                accessLabel!,
                                style: AppTypography.caption.copyWith(
                                  color: accessLabelColor ?? AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // if (showArrow) ...[
            //   const SizedBox(width: 8),
            //   const Icon(
            //     Icons.chevron_right_rounded,
            //     size: 26,
            //     color: Color(0xFF94A3B8),
            //   ),
            // ],

            // if (showArrow) ...[
            //   const SizedBox(width: 8),
            //   const Icon(
            //     Icons.chevron_right_rounded,
            //     size: 26,
            //     color: Color(0xFF94A3B8),
            //   ),
            // ] else if (status != null) ...[
            //   const SizedBox(width: 10),
            //   Container(
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 8,
            //       vertical: 4,
            //     ),
            //     decoration: BoxDecoration(
            //       color: effectiveStatusColor.withValues(alpha: 0.10),
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //     child: Text(
            //       status!,
            //       style: AppTypography.caption.copyWith(
            //         color: effectiveStatusColor,
            //         fontWeight: FontWeight.w600,
            //       ),
            //     ),
            //   ),
            // ],

            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                trailingIcon,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ] else if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: Color(0xFF94A3B8),
              ),
            ] else if (status != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: effectiveStatusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status!,
                  style: AppTypography.caption.copyWith(
                    color: effectiveStatusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
