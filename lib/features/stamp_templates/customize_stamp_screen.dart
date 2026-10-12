import 'package:flutter/material.dart';

import '../../core/models/stamp_style_settings.dart';
import '../../core/models/stamp_template.dart';
import '../../core/services/app_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';

void _ignoreLogoChange(bool _) {}

/// Screen 7 — Customize Stamp.
///
/// Stamp-only preview, visible-field toggles, and Size / Opacity sliders.
/// This edits the selected built-in stamp; it never creates another template.
class CustomizeStampScreen extends StatefulWidget {
  const CustomizeStampScreen({
    super.key,
    required this.templateIndex,
    required this.templateName,
    this.stampData,
  });

  final int templateIndex;
  final String templateName;

  /// Current live/frozen stamp forwarded by the caller.
  final GpsStampData? stampData;

  @override
  State<CustomizeStampScreen> createState() => _CustomizeStampScreenState();
}

class _CustomizeStampScreenState extends State<CustomizeStampScreen> {
  late bool _showMap;
  late bool _address;
  late bool _coordinates;
  late bool _dateTime;
  late bool _compass;
  late bool _altitude;
  double _size = 90;
  double _opacity = 80;

  @override
  void initState() {
    super.initState();
    _applyStyle(
      AppSettingsService.instance.stampStyleFor(widget.templateIndex),
    );
  }

  void _applyStyle(StampStyleSettings style) {
    // Map is a permanent part of the Map template. The user can customize
    // its information fields, but the map itself must never disappear.
    _showMap = widget.templateIndex == StampTemplate.map.index
        ? true
        : style.showMap;
    _address = style.showAddress;
    _coordinates = style.showCoordinates;
    _dateTime = style.showDateTime;
    _compass = style.showCompass;
    _altitude = style.showAltitude;
    _size = style.size;
    _opacity = style.opacity;
  }

  StampStyleSettings get _style => StampStyleSettings(
        showMap: widget.templateIndex == StampTemplate.map.index
            ? true
            : _showMap,
        showAddress: _address,
        showCoordinates: _coordinates,
        showDateTime: _dateTime,
        showCompass: _compass,
        showAltitude: _altitude,
        size: _size,
        opacity: _opacity,
      );

  int get _enabledFieldCount {
    final editableFields = <bool>[
      _address,
      _coordinates,
      _compass,
      _altitude,
      if (widget.templateIndex != StampTemplate.timeAndPlace.index) _dateTime,
    ];
    return editableFields.where((enabled) => enabled).length;
  }

  void _changeField({
    required bool currentValue,
    required bool newValue,
    required VoidCallback apply,
  }) {
    if (currentValue && !newValue && _enabledFieldCount <= 2) {
      AppTopToast.show(
        context,
        message: 'At least two fields must remain enabled.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(apply);
  }

  void _reset() {
    final settings = AppSettingsService.instance;
    final defaults = settings.resetStampStyle(widget.templateIndex);
    setState(() => _applyStyle(defaults));
    AppTopToast.show(
      context,
      message: 'Reset successfully',
      icon: Icons.refresh_rounded,
      backgroundColor: Colors.green,
    );
    Navigator.of(context).pop(false);
  }

  void _saveStyle() {
    if (_enabledFieldCount < 2) {
      AppTopToast.show(
        context,
        message: 'Enable at least two fields before saving.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final settings = AppSettingsService.instance;
    settings.saveStampStyle(
      widget.templateIndex,
      _style,
    );
    AppTopToast.show(
      context,
      message: 'Changes saved successfully',
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: Colors.green,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const previewLatitude = 8.7281;
    const previewLongitude = 77.7081;
    const fallbackData = GpsStampData(
          address: 'Location preview',
          title: 'Location preview',
          streetAddress: 'Current street and area',
          latitude: previewLatitude,
          longitude: previewLongitude,
          coordinates: 'Lat 8.728100° Long 77.708100°',
          dateTime: 'Saturday, 29/08/2026 02:30 PM',
          altitude: 'Altitude 16 m',
          compassDirection: 'NE 45°',
        );
    final suppliedData = widget.stampData;
    final data = suppliedData == null
        ? fallbackData
        : suppliedData.copyWith(
            latitude: suppliedData.latitude ?? previewLatitude,
            longitude: suppliedData.longitude ?? previewLongitude,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'Customize Stamp',
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'Reset',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.red,
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

                        LayoutBuilder(
                          builder: (context, previewConstraints) {
                            final scale = (_size / 90)
                                .clamp(0.40, 1.0)
                                .toDouble();
                            const badgeInset =
                                GpsStampTemplateOverlay.compactBadgeInset;
                            final surfaceHeight =
                                (previewConstraints.maxWidth * 0.16)
                                    .clamp(64.0, 88.0)
                                    .toDouble();
                            final previewHeight = surfaceHeight + badgeInset;
                            final isMinimal = widget.templateIndex ==
                                StampTemplate.minimal.index;

                            return Center(
                              child: SizedBox(
                                width: previewConstraints.maxWidth,
                                height: previewHeight,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FractionallySizedBox(
                                    widthFactor: scale,
                                    heightFactor: scale,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm / 2,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: badgeInset,
                                        ),
                                        child: isMinimal
                                            ? GpsStampTemplateOverlay(
                                                data: data,
                                                templateIndex:
                                                    widget.templateIndex,
                                                compact: true,
                                                mapSize: 60,
                                                styleOverride: _style,
                                              )
                                            : FittedBox(
                                                fit: BoxFit.fill,
                                                alignment: Alignment.center,
                                                child: SizedBox(
                                                  width: 520,
                                                  child:
                                                      GpsStampTemplateOverlay(
                                                    data: data,
                                                    templateIndex:
                                                        widget.templateIndex,
                                                    compact: true,
                                                    mapSize: 60,
                                                    styleOverride: _style,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                        Divider(height: 1, color: AppColors.border),

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
                          onChanged: (value) => _changeField(
                            currentValue: _address,
                            newValue: value,
                            apply: () => _address = value,
                          ),
                        ),
                        ToggleSettingRow(
                          icon: Icons.my_location_outlined,
                          title: 'Coordinates',
                          value: _coordinates,
                          onChanged: (value) => _changeField(
                            currentValue: _coordinates,
                            newValue: value,
                            apply: () => _coordinates = value,
                          ),
                        ),
                        if (widget.templateIndex !=
                            StampTemplate.timeAndPlace.index)
                          ToggleSettingRow(
                            icon: Icons.calendar_today_outlined,
                            title: 'Date & Time',
                            value: _dateTime,
                            onChanged: (value) => _changeField(
                              currentValue: _dateTime,
                              newValue: value,
                              apply: () => _dateTime = value,
                            ),
                          ),
                        ToggleSettingRow(
                          icon: Icons.explore_outlined,
                          title: 'Compass',
                          value: _compass,
                          onChanged: (value) => _changeField(
                            currentValue: _compass,
                            newValue: value,
                            apply: () => _compass = value,
                          ),
                        ),
                        ToggleSettingRow(
                          icon: Icons.terrain_outlined,
                          title: 'Altitude',
                          value: _altitude,
                          onChanged: (value) => _changeField(
                            currentValue: _altitude,
                            newValue: value,
                            apply: () => _altitude = value,
                          ),
                        ),
                        const IgnorePointer(
                          child: Opacity(
                            opacity: 0.45,
                            child: ToggleSettingRow(
                              icon: Icons.image_outlined,
                              title: 'Logo',
                              subtitle: 'Coming soon',
                              value: false,
                              onChanged: _ignoreLogoChange,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // -----------------------------------------------
                        // SIZE / OPACITY
                        // -----------------------------------------------

                        AppSlider(
                          label: 'Size',
                          value: _size,
                          min: 40,
                          max: 90,
                          onChanged: (v) => setState(() => _size = v),
                        ),
                        const SizedBox(height: 8),
                        AppSlider(
                          label: 'Opacity',
                          value: _opacity,
                          min: 10,
                          onChanged: (v) => setState(() => _opacity = v),
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
                    label: 'Save Changes',
                    icon: Icons.save_outlined,
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

}
