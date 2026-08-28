// import 'package:flutter/material.dart';

// import '../../core/services/sample_location_data.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_dimens.dart';
// import '../../core/theme/app_typography.dart';
// import '../../shared/widgets/widgets.dart';
// import 'customize_stamp_screen.dart';

// /// Describes one selectable stamp look. [kBuiltInStampTemplates] holds the
// /// built-in set from the mockup; templates the user builds in
// /// [CustomizeStampScreen] get appended to the same list at runtime.
// class StampTemplateInfo {
//   const StampTemplateInfo({
//     required this.label,
//     required this.visibility,
//     this.compact = false,
//     this.dark = true,
//     this.isCustom = false,
//   });

//   final String label;
//   final GpsStampFieldVisibility visibility;

//   /// Smaller padding/text — used for "Compact" and "Minimal".
//   final bool compact;

//   /// Dark semi-transparent card vs light solid card.
//   final bool dark;

//   /// User-created via Customize Stamp, shown with a "Custom" tag.
//   final bool isCustom;
// }

// const List<StampTemplateInfo> kBuiltInStampTemplates = [
//   StampTemplateInfo(
//     label: 'Classic',
//     visibility: GpsStampFieldVisibility(),
//   ),
//   StampTemplateInfo(
//     label: 'Compact',
//     compact: true,
//     visibility: GpsStampFieldVisibility(
//       dateTime: false,
//       weather: false,
//       altitude: false,
//     ),
//   ),
//   StampTemplateInfo(
//     label: 'Map Card',
//     visibility: GpsStampFieldVisibility(),
//   ),
//   StampTemplateInfo(
//     label: 'Field Work',
//     visibility: GpsStampFieldVisibility(
//       compass: true,
//       note: true,
//     ),
//   ),
//   StampTemplateInfo(
//     label: 'Minimal',
//     compact: true,
//     dark: false,
//     visibility: GpsStampFieldVisibility(
//       coordinates: false,
//       weather: false,
//       altitude: false,
//     ),
//   ),
//   StampTemplateInfo(
//     label: 'Branded',
//     dark: false,
//     visibility: GpsStampFieldVisibility(logo: true),
//   ),
// ];

// /// Screen 6 — Stamp Templates.
// ///
// /// Grid of stamp looks, each rendered with the real [GpsStampOverlay] so a
// /// template looks identical here as it does on a live photo. A "+ Custom"
// /// tile at the end opens [CustomizeStampScreen] to build a new one, which
// /// gets appended to the grid on return.
// ///
// /// When [selectionMode] is true (opened from Live Camera to pick a
// /// template for the next shot) "Apply Template" pops with the chosen
// /// index. When opened from Home ("Templates" quick action) it just manages
// /// the list in place.
// class StampTemplatesScreen extends StatefulWidget {
//   const StampTemplatesScreen({
//     super.key,
//     this.selectionMode = false,
//     this.initialSelectedIndex = 2, // "Map Card" — matches the mockup.
//   });

//   final bool selectionMode;
//   final int initialSelectedIndex;

//   @override
//   State<StampTemplatesScreen> createState() => _StampTemplatesScreenState();
// }

// class _StampTemplatesScreenState extends State<StampTemplatesScreen> {
//   late int _selectedIndex = widget.initialSelectedIndex;
//   final List<StampTemplateInfo> _templates = [...kBuiltInStampTemplates];

//   Future<void> _openCustomize() async {
//     final result = await Navigator.of(context).push<StampTemplateInfo>(
//       MaterialPageRoute(builder: (_) => const CustomizeStampScreen()),
//     );

//     if (result == null || !mounted) return;

//     setState(() {
//       _templates.add(result);
//       _selectedIndex = _templates.length - 1;
//     });
//   }

//   void _applyTemplate() {
//     if (widget.selectionMode) {
//       Navigator.of(context).pop(_selectedIndex);
//     } else {
//       Navigator.of(context).pop();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = SampleLocationData.current;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: const AppTopBar(title: 'Stamp Templates'),
//       body: SafeArea(
//         top: false,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final isWide = constraints.maxWidth >= 600;
//             final columns = isWide ? 3 : 2;
//             final horizontalPadding =
//                 isWide ? 32.0 : AppSpacing.screenPadding;

//             return Column(
//               children: [
//                 Expanded(
//                   child: GridView.builder(
//                     padding: EdgeInsets.fromLTRB(
//                       horizontalPadding,
//                       AppSpacing.md,
//                       horizontalPadding,
//                       AppSpacing.md,
//                     ),
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: columns,
//                       mainAxisSpacing: AppSpacing.md,
//                       crossAxisSpacing: AppSpacing.md,
//                       childAspectRatio: 0.82,
//                     ),
//                     itemCount: _templates.length + 1,
//                     itemBuilder: (context, index) {
//                       if (index == _templates.length) {
//                         return _CustomizeTile(onTap: _openCustomize);
//                       }

//                       final template = _templates[index];
//                       final selected = index == _selectedIndex;

//                       return _TemplateTile(
//                         template: template,
//                         data: data,
//                         selected: selected,
//                         onTap: () => setState(() => _selectedIndex = index),
//                       );
//                     },
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.fromLTRB(
//                     horizontalPadding,
//                     8,
//                     horizontalPadding,
//                     16,
//                   ),
//                   child: AppPrimaryButton(
//                     label: 'Apply Template',
//                     onPressed: _applyTemplate,
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // TEMPLATE TILE
// // =============================================================================

// class _TemplateTile extends StatelessWidget {
//   const _TemplateTile({
//     required this.template,
//     required this.data,
//     required this.selected,
//     required this.onTap,
//   });

//   final StampTemplateInfo template;
//   final GpsStampData data;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Expanded(
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(AppRadius.md),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: selected
//                             ? AppColors.primary
//                             : AppColors.border,
//                         width: selected ? 2 : 1,
//                       ),
//                       borderRadius: BorderRadius.circular(AppRadius.md),
//                       gradient: const LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Color(0xFF9CB5C8),
//                           Color(0xFF6F8590),
//                           Color(0xFF70513B),
//                         ],
//                       ),
//                     ),
//                     padding: const EdgeInsets.all(6),
//                     alignment: Alignment.bottomCenter,
//                     child: GpsStampOverlay(
//                       data: data,
//                       visibility: template.visibility,
//                       dark: template.dark,
//                       compact: true,
//                     ),
//                   ),
//                 ),
//                 if (selected)
//                   const Positioned(
//                     top: 8,
//                     right: 8,
//                     child: CircleAvatar(
//                       radius: 11,
//                       backgroundColor: AppColors.primary,
//                       child: Icon(
//                         Icons.check,
//                         size: 14,
//                         color: AppColors.white,
//                       ),
//                     ),
//                   ),
//                 if (template.isCustom)
//                   Positioned(
//                     top: 8,
//                     left: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary,
//                         borderRadius: BorderRadius.circular(AppRadius.sm),
//                       ),
//                       child: Text(
//                         'Custom',
//                         style: AppTypography.tiny.copyWith(
//                           color: AppColors.white,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             template.label,
//             style: AppTypography.caption.copyWith(
//               fontWeight: FontWeight.w600,
//               color: selected ? AppColors.primary : AppColors.textPrimary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =============================================================================
// // CUSTOMIZE TILE (grid entry point into CustomizeStampScreen)
// // =============================================================================

// class _CustomizeTile extends StatelessWidget {
//   const _CustomizeTile({required this.onTap});

//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Expanded(
//             child: DottedBorderBox(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: AppColors.primarySurface,
//                   borderRadius: BorderRadius.circular(AppRadius.md),
//                 ),
//                 alignment: Alignment.center,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: const BoxDecoration(
//                         color: AppColors.primary,
//                         shape: BoxShape.circle,
//                       ),
//                       alignment: Alignment.center,
//                       child: const Icon(
//                         Icons.add_rounded,
//                         color: AppColors.white,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Customize',
//                       style: AppTypography.caption.copyWith(
//                         color: AppColors.primary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Create your own',
//             style: AppTypography.caption.copyWith(
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Tiny dashed-border wrapper so the "+ Customize" tile visually reads as
// /// an add slot rather than another filled template.
// class DottedBorderBox extends StatelessWidget {
//   const DottedBorderBox({super.key, required this.child});

//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       painter: _DashedBorderPainter(),
//       child: child,
//     );
//   }
// }

// class _DashedBorderPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = AppColors.primary.withValues(alpha: 0.5)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5;

//     final rrect = RRect.fromRectAndRadius(
//       Offset.zero & size,
//       const Radius.circular(AppRadius.md),
//     );

//     const dashWidth = 6.0;
//     const dashSpace = 4.0;

//     final path = Path()..addRRect(rrect);

//     for (final metric in path.computeMetrics()) {
//       var distance = 0.0;
//       while (distance < metric.length) {
//         canvas.drawPath(
//           metric.extractPath(distance, distance + dashWidth),
//           paint,
//         );
//         distance += dashWidth + dashSpace;
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }





import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'customize_stamp_screen.dart';

/// Describes one selectable stamp look. [kBuiltInStampTemplates] holds the
/// built-in set from the mockup; templates the user builds in
/// [CustomizeStampScreen] get appended to the same list at runtime.
class StampTemplateInfo {
  const StampTemplateInfo({
    required this.label,
    required this.visibility,
    this.compact = false,
    this.dark = true,
    this.isCustom = false,
  });

  final String label;
  final GpsStampFieldVisibility visibility;

  /// Smaller padding/text — used for "Compact" and "Minimal".
  final bool compact;

  /// Dark semi-transparent card vs light solid card.
  final bool dark;

  /// User-created via Customize Stamp, shown with a "Custom" tag.
  final bool isCustom;
}

const List<StampTemplateInfo> kBuiltInStampTemplates = [
  StampTemplateInfo(
    label: 'Classic',
    visibility: GpsStampFieldVisibility(),
  ),
  StampTemplateInfo(
    label: 'Compact',
    compact: true,
    visibility: GpsStampFieldVisibility(
      dateTime: false,
      weather: false,
      altitude: false,
    ),
  ),
  StampTemplateInfo(
    label: 'Map Card',
    visibility: GpsStampFieldVisibility(),
  ),
  StampTemplateInfo(
    label: 'Field Work',
    visibility: GpsStampFieldVisibility(
      compass: true,
      note: true,
    ),
  ),
  StampTemplateInfo(
    label: 'Minimal',
    compact: true,
    dark: false,
    visibility: GpsStampFieldVisibility(
      coordinates: false,
      weather: false,
      altitude: false,
    ),
  ),
  StampTemplateInfo(
    label: 'Branded',
    dark: false,
    visibility: GpsStampFieldVisibility(logo: true),
  ),
];

/// Screen 6 — Stamp Templates.
///
/// Grid of stamp looks, each rendered with the real [GpsStampOverlay] so a
/// template looks identical here as it does on a live photo. A "+ Custom"
/// tile at the end opens [CustomizeStampScreen] to build a new one, which
/// gets appended to the grid on return.
///
/// When [selectionMode] is true (opened from Live Camera to pick a
/// template for the next shot) "Apply Template" pops with the chosen
/// index. When opened from Home ("Templates" quick action) it just manages
/// the list in place.
class StampTemplatesScreen extends StatefulWidget {
  const StampTemplatesScreen({
    super.key,
    this.selectionMode = false,
    this.initialSelectedIndex = 2, // "Map Card" — matches the mockup.
    this.stampData,
  });

  final bool selectionMode;
  final int initialSelectedIndex;

  /// Current live stamp from Camera, or frozen stamp from Capture Preview.
  final GpsStampData? stampData;

  @override
  State<StampTemplatesScreen> createState() => _StampTemplatesScreenState();
}

class _StampTemplatesScreenState extends State<StampTemplatesScreen> {
  late int _selectedIndex = widget.initialSelectedIndex;
  final List<StampTemplateInfo> _templates = [...kBuiltInStampTemplates];

  Future<void> _openCustomize() async {
    final result = await Navigator.of(context).push<StampTemplateInfo>(
      MaterialPageRoute(
        builder: (_) => CustomizeStampScreen(stampData: widget.stampData),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _templates.add(result);
      _selectedIndex = _templates.length - 1;
    });
  }

  void _applyTemplate() {
    if (widget.selectionMode) {
      Navigator.of(context).pop(_selectedIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.stampData ??
        const GpsStampData(
          address: 'Location preview',
          title: 'Location preview',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Stamp Templates'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final columns = isWide ? 3 : 2;
            final horizontalPadding =
                isWide ? 32.0 : AppSpacing.screenPadding;

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.md,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _templates.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _templates.length) {
                        return _CustomizeTile(onTap: _openCustomize);
                      }

                      final template = _templates[index];
                      final selected = index == _selectedIndex;

                      return _TemplateTile(
                        template: template,
                        data: data,
                        selected: selected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    16,
                  ),
                  child: AppPrimaryButton(
                    label: 'Apply Template',
                    onPressed: _applyTemplate,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// TEMPLATE TILE
// =============================================================================

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final StampTemplateInfo template;
  final GpsStampData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF9CB5C8),
                          Color(0xFF6F8590),
                          Color(0xFF70513B),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.bottomCenter,
                    child: GpsStampOverlay(
                      data: data,
                      visibility: template.visibility,
                      dark: template.dark,
                      compact: true,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                if (template.isCustom)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'Custom',
                        style: AppTypography.tiny.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            template.label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOMIZE TILE (grid entry point into CustomizeStampScreen)
// =============================================================================

class _CustomizeTile extends StatelessWidget {
  const _CustomizeTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: DottedBorderBox(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your own',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny dashed-border wrapper so the "+ Customize" tile visually reads as
/// an add slot rather than another filled template.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.md),
    );

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}