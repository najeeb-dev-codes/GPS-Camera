// import 'package:flutter/material.dart';

// import '../../core/services/sample_location_data.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_dimens.dart';
// import '../../core/theme/app_typography.dart';
// import '../../shared/widgets/widgets.dart';
// import 'stamp_templates_screen.dart';

// /// Screen 7 — Customize Stamp.
// ///
// /// Live preview of the GPS stamp on a sample photo, a "Visible fields"
// /// toggle list, a Map Type dropdown, Size / Opacity sliders, and a
// /// Corner Position picker. "Save Style" pops with a new
// /// [StampTemplateInfo] the caller can either drop straight onto the
// /// current photo ([CapturePreviewScreen]'s "Edit Stamp") or add to the
// /// template grid ([StampTemplatesScreen]'s "+ Customize").
// class CustomizeStampScreen extends StatefulWidget {
//   const CustomizeStampScreen({
//     super.key,
//     this.baseTemplate = const StampTemplateInfo(
//       label: 'Custom Stamp',
//       visibility: GpsStampFieldVisibility(),
//     ),
//   });

//   final StampTemplateInfo baseTemplate;

//   @override
//   State<CustomizeStampScreen> createState() => _CustomizeStampScreenState();
// }

// class _CustomizeStampScreenState extends State<CustomizeStampScreen> {
//   static const _mapTypes = ['Standard', 'Satellite', 'Terrain'];

//   late String _mapType = _mapTypes.first;

//   late bool _address = widget.baseTemplate.visibility.address;
//   late bool _coordinates = widget.baseTemplate.visibility.coordinates;
//   late bool _dateTime = widget.baseTemplate.visibility.dateTime;
//   late bool _weather = widget.baseTemplate.visibility.weather;
//   late bool _compass = widget.baseTemplate.visibility.compass;
//   late bool _altitude = widget.baseTemplate.visibility.altitude;
//   late bool _note = widget.baseTemplate.visibility.note;
//   late bool _logo = widget.baseTemplate.visibility.logo;

//   double _size = 90;
//   double _opacity = 80;
//   int _cornerIndex = 3; // bottom-right, matches the mockup's selected icon.

//   GpsStampFieldVisibility get _visibility => GpsStampFieldVisibility(
//         address: _address,
//         coordinates: _coordinates,
//         dateTime: _dateTime,
//         weather: _weather,
//         compass: _compass,
//         altitude: _altitude,
//         accuracy: true,
//         note: _note,
//         logo: _logo,
//       );

//   void _reset() {
//     setState(() {
//       _mapType = _mapTypes.first;
//       _address = true;
//       _coordinates = true;
//       _dateTime = true;
//       _weather = true;
//       _compass = false;
//       _altitude = true;
//       _note = false;
//       _logo = false;
//       _size = 90;
//       _opacity = 80;
//       _cornerIndex = 3;
//     });
//   }

//   void _saveStyle() {
//     Navigator.of(context).pop(
//       StampTemplateInfo(
//         label: 'Custom Style',
//         visibility: _visibility,
//         compact: _size < 70,
//         dark: true,
//         isCustom: true,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = SampleLocationData.current;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppTopBar(
//         title: 'Customize Stamp',
//         actions: [
//           TextButton(
//             onPressed: _reset,
//             child: Text(
//               'Reset',
//               style: AppTypography.bodyMedium.copyWith(
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         top: false,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final horizontalPadding = constraints.maxWidth >= 600
//                 ? 48.0
//                 : AppSpacing.screenPadding;

//             return Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.fromLTRB(
//                       horizontalPadding,
//                       12,
//                       horizontalPadding,
//                       24,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // -----------------------------------------------
//                         // LIVE PREVIEW
//                         // -----------------------------------------------

//                         AspectRatio(
//                           aspectRatio: 16 / 10,
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(AppRadius.md),
//                             child: Stack(
//                               fit: StackFit.expand,
//                               children: [
//                                 Container(
//                                   decoration: const BoxDecoration(
//                                     gradient: LinearGradient(
//                                       begin: Alignment.topCenter,
//                                       end: Alignment.bottomCenter,
//                                       colors: [
//                                         Color(0xFF9CB5C8),
//                                         Color(0xFF6F8590),
//                                         Color(0xFF70513B),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Align(
//                                   alignment: _alignmentForCorner(_cornerIndex),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(10),
//                                     child: Opacity(
//                                       opacity: _opacity / 100,
//                                       child: SizedBox(
//                                         width: (constraints.maxWidth -
//                                                 horizontalPadding * 2 -
//                                                 20) *
//                                             (_size / 100),
//                                         child: GpsStampOverlay(
//                                           data: data,
//                                           visibility: _visibility,
//                                           mapThumbnail:
//                                               const MapPreviewThumbnail(
//                                             size: 36,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 20),

//                         // -----------------------------------------------
//                         // MAP TYPE
//                         // -----------------------------------------------

//                         DropdownSettingRow<String>(
//                           title: 'Map Type',
//                           value: _mapType,
//                           items: _mapTypes,
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() => _mapType = value);
//                             }
//                           },
//                         ),

//                         const Divider(height: 1, color: AppColors.border),

//                         // -----------------------------------------------
//                         // VISIBLE FIELDS
//                         // -----------------------------------------------

//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           child: Text(
//                             'Visible fields',
//                             style: AppTypography.bodyMedium.copyWith(
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),

//                         ToggleSettingRow(
//                           icon: Icons.location_on_outlined,
//                           title: 'Address',
//                           value: _address,
//                           onChanged: (v) => setState(() => _address = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.explore_outlined,
//                           title: 'Compass',
//                           value: _compass,
//                           onChanged: (v) => setState(() => _compass = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.my_location_outlined,
//                           title: 'Coordinates',
//                           value: _coordinates,
//                           onChanged: (v) => setState(() => _coordinates = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.terrain_outlined,
//                           title: 'Altitude',
//                           value: _altitude,
//                           onChanged: (v) => setState(() => _altitude = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.calendar_today_outlined,
//                           title: 'Date & Time',
//                           value: _dateTime,
//                           onChanged: (v) => setState(() => _dateTime = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.note_outlined,
//                           title: 'Note',
//                           value: _note,
//                           onChanged: (v) => setState(() => _note = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.wb_sunny_outlined,
//                           title: 'Weather',
//                           value: _weather,
//                           onChanged: (v) => setState(() => _weather = v),
//                         ),
//                         ToggleSettingRow(
//                           icon: Icons.image_outlined,
//                           title: 'Logo',
//                           value: _logo,
//                           onChanged: (v) => setState(() => _logo = v),
//                         ),

//                         const SizedBox(height: 12),

//                         // -----------------------------------------------
//                         // SIZE / OPACITY
//                         // -----------------------------------------------

//                         AppSlider(
//                           label: 'Size',
//                           value: _size,
//                           onChanged: (v) => setState(() => _size = v),
//                         ),
//                         const SizedBox(height: 8),
//                         AppSlider(
//                           label: 'Opacity',
//                           value: _opacity,
//                           onChanged: (v) => setState(() => _opacity = v),
//                         ),

//                         const SizedBox(height: 16),

//                         // -----------------------------------------------
//                         // CORNER POSITION
//                         // -----------------------------------------------

//                         Text(
//                           'Corner Position',
//                           style: AppTypography.bodyMedium.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: List.generate(4, (index) {
//                             final selected = index == _cornerIndex;
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 10),
//                               child: GestureDetector(
//                                 onTap: () =>
//                                     setState(() => _cornerIndex = index),
//                                 child: Container(
//                                   width: 44,
//                                   height: 44,
//                                   decoration: BoxDecoration(
//                                     color: selected
//                                         ? AppColors.primarySurface
//                                         : AppColors.white,
//                                     borderRadius:
//                                         BorderRadius.circular(AppRadius.sm),
//                                     border: Border.all(
//                                       color: selected
//                                           ? AppColors.primary
//                                           : AppColors.border,
//                                       width: selected ? 1.5 : 1,
//                                     ),
//                                   ),
//                                   child: Icon(
//                                     _cornerIcon(index),
//                                     size: 18,
//                                     color: selected
//                                         ? AppColors.primary
//                                         : AppColors.neutral400,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }),
//                         ),
//                       ],
//                     ),
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
//                     label: 'Save Style',
//                     onPressed: _saveStyle,
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Alignment _alignmentForCorner(int index) => switch (index) {
//         0 => Alignment.topLeft,
//         1 => Alignment.topRight,
//         2 => Alignment.bottomLeft,
//         _ => Alignment.bottomRight,
//       };

//   IconData _cornerIcon(int index) => switch (index) {
//         0 => Icons.north_west_rounded,
//         1 => Icons.north_east_rounded,
//         2 => Icons.south_west_rounded,
//         _ => Icons.south_east_rounded,
//       };
// }'



import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'stamp_templates_screen.dart';

/// Screen 7 — Customize Stamp.
///
/// Live preview of the GPS stamp on a sample photo, a "Visible fields"
/// toggle list, a Map Type dropdown, Size / Opacity sliders, and a
/// Corner Position picker. "Save Style" pops with a new
/// [StampTemplateInfo] the caller can either drop straight onto the
/// current photo ([CapturePreviewScreen]'s "Edit Stamp") or add to the
/// template grid ([StampTemplatesScreen]'s "+ Customize").
class CustomizeStampScreen extends StatefulWidget {
  const CustomizeStampScreen({
    super.key,
    this.stampData,
    this.baseTemplate = const StampTemplateInfo(
      label: 'Custom Stamp',
      visibility: GpsStampFieldVisibility(),
    ),
  });

  /// Current live/frozen stamp forwarded by the caller.
  final GpsStampData? stampData;

  final StampTemplateInfo baseTemplate;

  @override
  State<CustomizeStampScreen> createState() => _CustomizeStampScreenState();
}

class _CustomizeStampScreenState extends State<CustomizeStampScreen> {
  static const _mapTypes = ['Standard', 'Satellite', 'Terrain'];

  late String _mapType = _mapTypes.first;

  late bool _address = widget.baseTemplate.visibility.address;
  late bool _coordinates = widget.baseTemplate.visibility.coordinates;
  late bool _dateTime = widget.baseTemplate.visibility.dateTime;
  late bool _weather = widget.baseTemplate.visibility.weather;
  late bool _compass = widget.baseTemplate.visibility.compass;
  late bool _altitude = widget.baseTemplate.visibility.altitude;
  late bool _note = widget.baseTemplate.visibility.note;
  late bool _logo = widget.baseTemplate.visibility.logo;

  double _size = 90;
  double _opacity = 80;
  int _cornerIndex = 3; // bottom-right, matches the mockup's selected icon.

  GpsStampFieldVisibility get _visibility => GpsStampFieldVisibility(
        address: _address,
        coordinates: _coordinates,
        dateTime: _dateTime,
        weather: _weather,
        compass: _compass,
        altitude: _altitude,
        accuracy: true,
        note: _note,
        logo: _logo,
      );

  void _reset() {
    setState(() {
      _mapType = _mapTypes.first;
      _address = true;
      _coordinates = true;
      _dateTime = true;
      _weather = true;
      _compass = false;
      _altitude = true;
      _note = false;
      _logo = false;
      _size = 90;
      _opacity = 80;
      _cornerIndex = 3;
    });
  }

  void _saveStyle() {
    Navigator.of(context).pop(
      StampTemplateInfo(
        label: 'Custom Style',
        visibility: _visibility,
        compact: _size < 70,
        dark: true,
        isCustom: true,
      ),
    );
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
      appBar: AppTopBar(
        title: 'Customize Stamp',
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'Reset',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? 48.0
                : AppSpacing.screenPadding;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -----------------------------------------------
                        // LIVE PREVIEW
                        // -----------------------------------------------

                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF9CB5C8),
                                        Color(0xFF6F8590),
                                        Color(0xFF70513B),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: _alignmentForCorner(_cornerIndex),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Opacity(
                                      opacity: _opacity / 100,
                                      child: SizedBox(
                                        width: (constraints.maxWidth -
                                                horizontalPadding * 2 -
                                                20) *
                                            (_size / 100),
                                        child: GpsStampOverlay(
                                          data: data,
                                          visibility: _visibility,
                                          mapThumbnail:
                                              const MapPreviewThumbnail(
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // -----------------------------------------------
                        // MAP TYPE
                        // -----------------------------------------------

                        DropdownSettingRow<String>(
                          title: 'Map Type',
                          value: _mapType,
                          items: _mapTypes,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _mapType = value);
                            }
                          },
                        ),

                        const Divider(height: 1, color: AppColors.border),

                        // -----------------------------------------------
                        // VISIBLE FIELDS
                        // -----------------------------------------------

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Visible fields',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        ToggleSettingRow(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          value: _address,
                          onChanged: (v) => setState(() => _address = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.explore_outlined,
                          title: 'Compass',
                          value: _compass,
                          onChanged: (v) => setState(() => _compass = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.my_location_outlined,
                          title: 'Coordinates',
                          value: _coordinates,
                          onChanged: (v) => setState(() => _coordinates = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.terrain_outlined,
                          title: 'Altitude',
                          value: _altitude,
                          onChanged: (v) => setState(() => _altitude = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Date & Time',
                          value: _dateTime,
                          onChanged: (v) => setState(() => _dateTime = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.note_outlined,
                          title: 'Note',
                          value: _note,
                          onChanged: (v) => setState(() => _note = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Weather',
                          value: _weather,
                          onChanged: (v) => setState(() => _weather = v),
                        ),
                        ToggleSettingRow(
                          icon: Icons.image_outlined,
                          title: 'Logo',
                          value: _logo,
                          onChanged: (v) => setState(() => _logo = v),
                        ),

                        const SizedBox(height: 12),

                        // -----------------------------------------------
                        // SIZE / OPACITY
                        // -----------------------------------------------

                        AppSlider(
                          label: 'Size',
                          value: _size,
                          onChanged: (v) => setState(() => _size = v),
                        ),
                        const SizedBox(height: 8),
                        AppSlider(
                          label: 'Opacity',
                          value: _opacity,
                          onChanged: (v) => setState(() => _opacity = v),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------
                        // CORNER POSITION
                        // -----------------------------------------------

                        Text(
                          'Corner Position',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(4, (index) {
                            final selected = index == _cornerIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _cornerIndex = index),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primarySurface
                                        : AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _cornerIcon(index),
                                    size: 18,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.neutral400,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
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
                    label: 'Save Style',
                    onPressed: _saveStyle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Alignment _alignmentForCorner(int index) => switch (index) {
        0 => Alignment.topLeft,
        1 => Alignment.topRight,
        2 => Alignment.bottomLeft,
        _ => Alignment.bottomRight,
      };

  IconData _cornerIcon(int index) => switch (index) {
        0 => Icons.north_west_rounded,
        1 => Icons.north_east_rounded,
        2 => Icons.south_west_rounded,
        _ => Icons.south_east_rounded,
      };
}