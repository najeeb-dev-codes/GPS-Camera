import 'package:flutter/material.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/models/stamp_template.dart';
import '../../../core/models/stamp_style_settings.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'gps_stamp_overlay.dart';
import 'map_preview_thumbnail.dart';

final List<String> kGpsStampTemplateNames = kStampTemplateLabels;

/// Shared renderer used by the picker, live camera and saved image.
class GpsStampTemplateOverlay extends StatelessWidget {
  const GpsStampTemplateOverlay({
    super.key,
    required this.data,
    required this.templateIndex,
    this.compact = false,
    this.landscapeLayout = false,
    this.mapSize,
    this.styleOverride,
  });

  final GpsStampData data;
  final int templateIndex;
  final bool compact;
  final bool landscapeLayout;
  final double? mapSize;
  final StampStyleSettings? styleOverride;

  /// Space required above a compact stamp for the GPS Mark badge.
  ///
  /// The badge intentionally overlaps the top edge of the stamp. Preview
  /// containers use this value to reserve enough room instead of clipping it.
  static const double compactBadgeInset = 17;

  int get _index => StampTemplate.fromIndex(templateIndex).index;
  String get _title => data.title ?? data.address;
  String get _address => data.streetAddress ?? data.address;
  String get _coordinates => data.coordinates ?? 'Coordinates unavailable';

  String get _dateTime {
    final value = data.dateTime ?? 'Date and time unavailable';
    return value.replaceAllMapped(
      RegExp(r'(\d{1,2}:\d{2}):\d{2}'),
      (match) => match.group(1)!,
    );
  }

  String get _timeOnly {
    final match = RegExp(
      r'(\d{1,2}:\d{2})(?::\d{2})?\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(data.dateTime ?? '');
    if (match == null) return '--:--';
    final period = match.group(2);
    return period == null
        ? match.group(1)!
        : '${match.group(1)} ${period.toUpperCase()}';
  }

  String get _dateOnly {
    return _dateTime
        .replaceFirst(
          RegExp(r'\s+\d{1,2}:\d{2}\s*(?:AM|PM)?', caseSensitive: false),
          '',
        )
        .trim();
  }

  double get _resolvedMapSize => mapSize ?? (compact ? 48 : 86);

  TextStyle _titleStyle(Color color) => AppTypography.h3.copyWith(
        color: color,
        fontSize: compact ? (landscapeLayout ? 12 : 11) : 16,
        fontWeight: FontWeight.w700,
      );

  TextStyle _detailStyle(Color color) => AppTypography.stampLabel.copyWith(
        color: color,
        fontSize: compact ? (landscapeLayout ? 10 : 9) : 11,
        height: compact ? 1.12 : 1.35,
      );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final style = styleOverride ?? settings.stampStyleFor(_index);
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : (compact ? 400.0 : 800.0);
            final sectionGap = (width * 0.02).clamp(4.0, 14.0).toDouble();
            final stamp = switch (_index) {
              1 => _locationCard(settings, style, sectionGap),
              2 => _timeAndPlace(settings, style, sectionGap),
              3 => _minimalProof(settings, style, sectionGap),
              _ => _mapProof(settings, style, sectionGap),
            };
            final badgeColor = switch (_index) {
              1 => const Color(0xEC0B0D10),
              2 => const Color(0xEE0B0D10),
              3 => AppColors.white.withValues(alpha: 0.96),
              _ => const Color(0xE8101822),
            };
            return Opacity(
              opacity: (style.opacity / 100).clamp(0.10, 1.0),
              child: _TopBadgeStamp(
                compact: compact,
                landscapeLayout: landscapeLayout,
                dark: _index != 3,
                backgroundColor: badgeColor,
                child: stamp,
              ),
            );
          },
        );
      },
    );
  }

  Widget _mapProof(
    AppSettingsService settings,
    StampStyleSettings style,
    double sectionGap,
  ) {
    final mapVerticalGap = _resolvedMapSize * 0.02;
    final mapContentSize = _resolvedMapSize - (mapVerticalGap * 2);
    return _StampSurface(
      compact: compact,
      color: const Color(0xE8101822),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: mapVerticalGap),
            child: _mapFrame(mapContentSize),
          ),
          SizedBox(width: sectionGap),
          Expanded(child: _details(settings, style, dark: true)),
        ],
      ),
    );
  }

  Widget _locationCard(
    AppSettingsService settings,
    StampStyleSettings style,
    double sectionGap,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xEC0B0D10),
      rightInsetFactor: 0.04,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (style.showMap) ...[
            _mapFrame(_resolvedMapSize),
            SizedBox(width: sectionGap),
          ],
          Expanded(child: _details(settings, style, dark: true)),
        ],
      ),
    );
  }

  Widget _timeAndPlace(
    AppSettingsService settings,
    StampStyleSettings style,
    double sectionGap,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xEE0B0D10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (style.showMap || style.showDateTime) ...[
            if (style.showMap)
              _mapFrame(_resolvedMapSize)
            else
              SizedBox(
                width: compact ? 70 : 112,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeOnly,
                      style: _titleStyle(AppColors.white).copyWith(
                        fontSize: compact ? (landscapeLayout ? 15 : 14) : 22,
                      ),
                    ),
                    _line(
                      _dateOnly,
                      AppColors.textOnDarkSecondary,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            Container(
              width: 1,
              height: _resolvedMapSize,
              margin: EdgeInsets.symmetric(horizontal: sectionGap),
              color: AppColors.white.withValues(alpha: 0.50),
            ),
          ],
          Expanded(
            child: _StampContentFitter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (style.showAddress) _header(dark: true),
                  if (style.showAddress)
                    _line(
                      _address,
                      AppColors.textOnDarkSecondary,
                      maxLines: 2,
                    ),
                  if (style.showCoordinates)
                    _line(_coordinates, AppColors.textOnDarkSecondary),
                  _optionalGps(settings, style, AppColors.textOnDarkSecondary),
                  _bottomRow(
                    style.showDateTime ? _dateTime : '',
                    dark: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _minimalProof(
    AppSettingsService settings,
    StampStyleSettings style,
    double sectionGap,
  ) {
    final locationIconSize = compact
        ? (_resolvedMapSize * 0.62).clamp(30.0, 40.0).toDouble()
        : 44.0;

    return _StampSurface(
      compact: compact,
      color: AppColors.white.withValues(alpha: 0.96),
      accent: AppColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (style.showMap)
            _mapFrame(_resolvedMapSize)
          else
            SizedBox.square(
              dimension: locationIconSize,
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: locationIconSize,
              ),
            ),
          SizedBox(width: sectionGap),
          Expanded(child: _details(settings, style, dark: false)),
        ],
      ),
    );
  }

  Widget _details(
    AppSettingsService settings,
    StampStyleSettings style, {
    required bool dark,
  }) {
    final secondary =
        dark ? AppColors.textOnDarkSecondary : AppColors.lightTextSecondary;
    return _StampContentFitter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showAddress) _header(dark: dark),
          if (style.showAddress) _line(_address, secondary, maxLines: 2),
          if (style.showCoordinates) _line(_coordinates, secondary),
          _optionalGps(settings, style, secondary),
          _bottomRow(
            style.showDateTime ? _dateTime : '',
            dark: dark,
          ),
        ],
      ),
    );
  }

  Widget _mapFrame(double size) {
    return SizedBox.square(
      dimension: size,
      child: MapPreviewThumbnail(
        size: size,
        latitude: data.latitude,
        longitude: data.longitude,
      ),
    );
  }

  Widget _header({required bool dark}) {
    final color = dark ? AppColors.white : AppColors.lightTextPrimary;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _title,
                  style: _titleStyle(color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.flagEmoji != null) ...[
                SizedBox(width: compact ? 3 : 6),
                Text(
                  data.flagEmoji!,
                  style: TextStyle(fontSize: compact ? 10 : 15),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomRow(
    String value, {
    required bool dark,
  }) {
    final color =
        dark ? AppColors.textOnDarkSecondary : AppColors.lightTextSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            value,
            style: _detailStyle(color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _line(String value, Color color, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 1 : 2),
      child: Text(
        value,
        style: _detailStyle(color),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _optionalGps(
    AppSettingsService settings,
    StampStyleSettings style,
    Color color,
  ) {
    final facts = <Widget>[];
    if (settings.showAccuracy && data.accuracy != null) {
      facts.add(_MiniFact(
        icon: Icons.gps_fixed_rounded,
        text: data.accuracy!,
        color: color,
        compact: compact,
        landscapeLayout: landscapeLayout,
      ));
    }
    if (style.showAltitude && data.altitude != null) {
      facts.add(_MiniFact(
        icon: Icons.terrain_outlined,
        text: data.altitude!,
        color: color,
        compact: compact,
        landscapeLayout: landscapeLayout,
      ));
    }
    if (style.showCompass && data.compassDirection != null) {
      facts.add(_MiniFact(
        icon: Icons.explore_outlined,
        text: data.compassDirection!,
        color: color,
        compact: compact,
        landscapeLayout: landscapeLayout,
      ));
    }
    if (facts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: compact ? 2 : 4),
      child: Wrap(
        spacing: compact ? 6 : 12,
        runSpacing: 3,
        children: facts,
      ),
    );
  }
}

class _TopBadgeStamp extends StatelessWidget {
  const _TopBadgeStamp({
    required this.compact,
    required this.landscapeLayout,
    required this.dark,
    required this.backgroundColor,
    required this.child,
  });

  final bool compact;
  final bool landscapeLayout;
  final bool dark;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final badgeHeight = compact ? 20.0 : 32.0;
    final overlap = compact ? 3.0 : 5.0;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -(badgeHeight - overlap),
          right: 0,
          child: _AppTag(
            compact: compact,
            landscapeLayout: landscapeLayout,
            dark: dark,
            backgroundColor: backgroundColor,
            showIcon: true,
          ),
        ),
      ],
    );
  }
}

/// Scales only textual stamp content when a small device or a long translated
/// address needs extra room. Map elements remain perfectly square.
class _StampContentFitter extends StatelessWidget {
  const _StampContentFitter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) return child;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(width: constraints.maxWidth, child: child),
        );
      },
    );
  }
}

class _StampSurface extends StatelessWidget {
  const _StampSurface({
    required this.child,
    required this.color,
    required this.compact,
    this.accent,
    this.rightInsetFactor = 0.02,
  });

  final Widget child;
  final Color color;
  final bool compact;
  final Color? accent;
  final double rightInsetFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (compact ? 400.0 : 800.0);
        final gap = (width * 0.02).clamp(4.0, 14.0).toDouble();
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (compact ? 80.0 : 140.0);
        final verticalGap = (height * 0.02).clamp(2.0, 6.0).toDouble();
        final rightGap = (width * rightInsetFactor).clamp(gap, 40.0).toDouble();
        return Container(
          padding: EdgeInsets.fromLTRB(gap, verticalGap, rightGap, verticalGap),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(compact ? 4 : 7),
              bottomLeft: Radius.circular(compact ? 4 : 7),
              bottomRight: Radius.circular(compact ? 4 : 7),
            ),
            border: accent == null
                ? Border.all(color: AppColors.white.withValues(alpha: 0.18))
                : Border(
                    left: BorderSide(
                      color: accent!,
                      width: compact ? 4 : 6,
                    ),
                  ),
            boxShadow: compact
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: child,
        );
      },
    );
  }
}

class _AppTag extends StatelessWidget {
  const _AppTag({
    required this.compact,
    required this.landscapeLayout,
    required this.dark,
    required this.backgroundColor,
    required this.showIcon,
  });

  final bool compact;
  final bool landscapeLayout;
  final bool dark;
  final Color backgroundColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 24.0;
    final horizontalPadding = compact ? 3.0 : 6.0;
    final verticalPadding = compact ? 2.0 : 4.0;
    final labelSize = compact ? (landscapeLayout ? 8.5 : 8.0) : 10.0;

    return Container(
      constraints: BoxConstraints(
        minHeight: iconSize + (verticalPadding * 2),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Image.asset(
              'assets/icon/app_icon.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.camera_alt_rounded,
                size: iconSize,
                color: dark ? AppColors.white : AppColors.primary,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            AppBrand.name,
            style: AppTypography.tiny.copyWith(
              color: dark ? AppColors.white : AppColors.primary,
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({
    required this.icon,
    required this.text,
    required this.color,
    required this.compact,
    required this.landscapeLayout,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool compact;
  final bool landscapeLayout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? (landscapeLayout ? 9 : 8) : 12,
          color: color,
        ),
        SizedBox(width: compact ? 2 : 3),
        Text(
          text,
          style: AppTypography.tiny.copyWith(
            color: color,
            fontSize: compact ? (landscapeLayout ? 9 : 8) : 9.5,
          ),
        ),
      ],
    );
  }
}
