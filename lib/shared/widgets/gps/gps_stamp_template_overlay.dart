import 'package:flutter/material.dart';

import '../../../core/models/stamp_style_settings.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'gps_stamp_overlay.dart';
import 'map_preview_thumbnail.dart';

const List<String> kGpsStampTemplateNames = <String>[
  'Map',
  'Default',
  'QR',
  'Time & Place',
  'Minimal',
];

/// Shared five-style renderer used by the picker, live camera and saved image.
class GpsStampTemplateOverlay extends StatelessWidget {
  const GpsStampTemplateOverlay({
    super.key,
    required this.data,
    required this.templateIndex,
    this.compact = false,
    this.mapSize,
    this.styleOverride,
  });

  final GpsStampData data;
  final int templateIndex;
  final bool compact;
  final double? mapSize;
  final StampStyleSettings? styleOverride;

  int get _index => templateIndex.clamp(0, 4).toInt();
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
        fontSize: compact ? 10 : 16,
        fontWeight: FontWeight.w700,
      );

  TextStyle _detailStyle(Color color) => AppTypography.stampLabel.copyWith(
        color: color,
        fontSize: compact ? 8 : 11,
        height: compact ? 1.20 : 1.35,
      );

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final style = styleOverride ?? settings.stampStyleFor(_index);
        return Opacity(
          opacity: (style.opacity / 100).clamp(0.10, 1.0),
          child: switch (_index) {
            1 => _locationCard(settings, style),
            2 => _qrSplit(settings, style),
            3 => _timeAndPlace(settings, style),
            4 => _minimalProof(settings, style),
            _ => _mapProof(settings, style),
          },
        );
      },
    );
  }

  Widget _mapProof(
    AppSettingsService settings,
    StampStyleSettings style,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xE8101822),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showMap) ...[
            MapPreviewThumbnail(
              size: _resolvedMapSize,
              latitude: data.latitude,
              longitude: data.longitude,
            ),
            SizedBox(width: compact ? 6 : 12),
          ],
          Expanded(child: _details(settings, style, dark: true)),
        ],
      ),
    );
  }

  Widget _locationCard(
    AppSettingsService settings,
    StampStyleSettings style,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xEC0B0D10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showMap) ...[
            MapPreviewThumbnail(
              size: _resolvedMapSize,
              latitude: data.latitude,
              longitude: data.longitude,
            ),
            SizedBox(width: compact ? 6 : 12),
          ],
          Expanded(child: _details(settings, style, dark: true)),
        ],
      ),
    );
  }

  Widget _qrSplit(
    AppSettingsService settings,
    StampStyleSettings style,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xEC101214),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showMap)
            MapPreviewThumbnail(
              size: compact ? 60 : 90,
              latitude: data.latitude,
              longitude: data.longitude,
            )
          else
            _LocationCode(
              value: '${data.latitude},${data.longitude}',
              size: compact ? 60 : 90,
            ),
          Container(
            width: 1,
            height: compact ? 60 : 90,
            margin: EdgeInsets.symmetric(horizontal: compact ? 7 : 14),
            color: AppColors.white.withValues(alpha: 0.50),
          ),
          Expanded(child: _details(settings, style, dark: true)),
        ],
      ),
    );
  }

  Widget _timeAndPlace(
    AppSettingsService settings,
    StampStyleSettings style,
  ) {
    return _StampSurface(
      compact: compact,
      color: const Color(0xEE0B0D10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showMap || style.showDateTime) ...[
            if (style.showMap)
              MapPreviewThumbnail(
                size: compact ? 60 : 90,
                latitude: data.latitude,
                longitude: data.longitude,
              )
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
                        fontSize: compact ? 13 : 22,
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
              height: compact ? 52 : 78,
              margin: EdgeInsets.symmetric(horizontal: compact ? 7 : 14),
              color: AppColors.white.withValues(alpha: 0.50),
            ),
          ],
          Expanded(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _minimalProof(
    AppSettingsService settings,
    StampStyleSettings style,
  ) {
    return _StampSurface(
      compact: compact,
      color: AppColors.white.withValues(alpha: 0.96),
      accent: AppColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showMap)
            MapPreviewThumbnail(
              size: _resolvedMapSize,
              latitude: data.latitude,
              longitude: data.longitude,
            )
          else
            Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: compact ? 19 : 28,
            ),
          SizedBox(width: compact ? 6 : 11),
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
        dark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (style.showAddress) _header(dark: dark),
        if (style.showAddress) _line(_address, secondary, maxLines: 2),
        if (style.showCoordinates) _line(_coordinates, secondary),
        if (style.showDateTime) _line(_dateTime, secondary),
        _optionalGps(settings, style, secondary),
      ],
    );
  }

  Widget _header({required bool dark}) {
    final color = dark ? AppColors.white : AppColors.textPrimary;
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
        SizedBox(width: compact ? 3 : 7),
        _AppTag(
          compact: compact,
          dark: dark,
          showIcon: _index != 4,
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
      ));
    }
    if (style.showAltitude && data.altitude != null) {
      facts.add(_MiniFact(
        icon: Icons.terrain_outlined,
        text: data.altitude!,
        color: color,
        compact: compact,
      ));
    }
    if (style.showCompass && data.compassDirection != null) {
      facts.add(_MiniFact(
        icon: Icons.explore_outlined,
        text: data.compassDirection!,
        color: color,
        compact: compact,
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

class _StampSurface extends StatelessWidget {
  const _StampSurface({
    required this.child,
    required this.color,
    required this.compact,
    this.accent,
  });

  final Widget child;
  final Color color;
  final bool compact;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 8 : 14),
        border: accent == null
            ? Border.all(color: AppColors.white.withValues(alpha: 0.18))
            : Border(
                left: BorderSide(
                  color: accent!,
                  width: compact ? 3 : 5,
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
  }
}

class _AppTag extends StatelessWidget {
  const _AppTag({
    required this.compact,
    required this.dark,
    required this.showIcon,
  });

  final bool compact;
  final bool dark;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 28.0;
    final horizontalPadding = compact ? 4.0 : 7.0;
    final verticalPadding = compact ? 3.0 : 5.0;
    final labelSize = compact ? 8.0 : 11.0;

    return Container(
      constraints: BoxConstraints(
        // Minimal has no icon, but its tag keeps the shared tag height.
        minHeight: iconSize + (verticalPadding * 2),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.neutral900.withValues(alpha: 0.72)
            : AppColors.primarySurface,
        border: Border.all(
          color: dark
              ? AppColors.white.withValues(alpha: 0.55)
              : AppColors.primary.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(999),
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
            'GPS Camera',
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
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 7 : 12, color: color),
        SizedBox(width: compact ? 2 : 3),
        Text(
          text,
          style: AppTypography.tiny.copyWith(
            color: color,
            fontSize: compact ? 7 : 9.5,
          ),
        ),
      ],
    );
  }
}

class _LocationCode extends StatelessWidget {
  const _LocationCode({required this.value, required this.size});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size < 60 ? 3 : 6),
      ),
      child: CustomPaint(painter: _LocationCodePainter(value)),
    );
  }
}

class _LocationCodePainter extends CustomPainter {
  const _LocationCodePainter(this.value);

  final String value;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 17;
    final cell = size.width / cells;
    final black = Paint()..color = AppColors.neutral900;
    final white = Paint()..color = AppColors.white;
    var seed = value.hashCode.abs();

    void finder(int x, int y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cell, y * cell, 5 * cell, 5 * cell),
        black,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + 1) * cell, (y + 1) * cell, 3 * cell, 3 * cell),
        white,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + 2) * cell, (y + 2) * cell, cell, cell),
        black,
      );
    }

    finder(0, 0);
    finder(12, 0);
    finder(0, 12);

    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final inFinder = (x < 5 && y < 5) ||
            (x >= 12 && y < 5) ||
            (x < 5 && y >= 12);
        if (inFinder) continue;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        if (seed.isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            black,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LocationCodePainter oldDelegate) =>
      oldDelegate.value != value;
}
