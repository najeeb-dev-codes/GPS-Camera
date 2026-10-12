import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// Model containing the live GPS/location information displayed inside
/// the stamp.
class GpsStampData {
  const GpsStampData({
    required this.address,
    this.title,
    this.flagEmoji,
    this.streetAddress,
    this.latitude,
    this.longitude,
    this.street,
    this.area,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.coordinates,
    this.dateTime,
    this.weather,
    this.pressure,
    this.accuracy,
    this.altitude,
    this.compassDirection,
    this.note,
  });

  /// Legacy/fallback full address.
  final String address;

  /// Short "City, State, Country" title.
  final String? title;

  /// Country flag emoji, for example 🇮🇳.
  final String? flagEmoji;

  /// Full reverse-geocoded street address used by the overlay.
  final String? streetAddress;

  /// Raw live coordinates. These are intentionally stored as numbers so the
  /// exact GPS fix can be frozen with the photo and restored later.
  final double? latitude;
  final double? longitude;

  /// Raw reverse-geocoded address parts.
  final String? street;
  final String? area;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  /// Preformatted values displayed by the stamp.
  final String? coordinates;
  final String? dateTime;
  final String? weather;
  final String? pressure;
  final String? accuracy;
  final String? altitude;
  final String? compassDirection;
  final String? note;

  GpsStampData copyWith({
    String? address,
    String? title,
    String? flagEmoji,
    String? streetAddress,
    double? latitude,
    double? longitude,
    String? street,
    String? area,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? coordinates,
    String? dateTime,
    String? weather,
    String? pressure,
    String? accuracy,
    String? altitude,
    String? compassDirection,
    String? note,
  }) {
    return GpsStampData(
      address: address ?? this.address,
      title: title ?? this.title,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      streetAddress: streetAddress ?? this.streetAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      street: street ?? this.street,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      coordinates: coordinates ?? this.coordinates,
      dateTime: dateTime ?? this.dateTime,
      weather: weather ?? this.weather,
      pressure: pressure ?? this.pressure,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      compassDirection: compassDirection ?? this.compassDirection,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'address': address,
      'title': title,
      'flagEmoji': flagEmoji,
      'streetAddress': streetAddress,
      'latitude': latitude,
      'longitude': longitude,
      'street': street,
      'area': area,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'coordinates': coordinates,
      'dateTime': dateTime,
      'weather': weather,
      'pressure': pressure,
      'accuracy': accuracy,
      'altitude': altitude,
      'compassDirection': compassDirection,
      'note': note,
    };
  }

  factory GpsStampData.fromJson(Map<String, dynamic> json) {
    return GpsStampData(
      address: (json['address'] as String?) ?? 'Location unavailable',
      title: json['title'] as String?,
      flagEmoji: json['flagEmoji'] as String?,
      streetAddress: json['streetAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      street: json['street'] as String?,
      area: json['area'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      coordinates: json['coordinates'] as String?,
      dateTime: json['dateTime'] as String?,
      weather: json['weather'] as String?,
      pressure: json['pressure'] as String?,
      accuracy: json['accuracy'] as String?,
      altitude: json['altitude'] as String?,
      compassDirection: json['compassDirection'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// Controls which fields are visible inside the GPS stamp.
class GpsStampFieldVisibility {
  const GpsStampFieldVisibility({
    this.address = true,
    this.coordinates = true,
    this.dateTime = true,
    this.weather = true,
    this.compass = false,
    this.altitude = true,
    this.accuracy = true,
    this.note = false,
    this.logo = false,
  });

  final bool address;
  final bool coordinates;
  final bool dateTime;
  final bool weather;
  final bool compass;
  final bool altitude;
  final bool accuracy;
  final bool note;
  final bool logo;
}

/// GPS stamp overlay used by:
/// - Live Camera
/// - Capture Preview
/// - Customize Stamp
/// - Photo Details
/// - Save Success
/// - Stamp Template previews
class GpsStampOverlay extends StatelessWidget {
  const GpsStampOverlay({
    super.key,
    required this.data,
    this.visibility = const GpsStampFieldVisibility(),
    this.dark = true,
    this.compact = false,
    this.mapThumbnail,
  });

  final GpsStampData data;
  final GpsStampFieldVisibility visibility;

  /// Dark semi-transparent stamp.
  final bool dark;

  /// Smaller version used for template previews.
  final bool compact;

  /// Optional map thumbnail shown on the left side.
  final Widget? mapThumbnail;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = dark
        ? AppColors.neutral900.withValues(alpha: 0.78)
        : AppColors.white;

    final textColor = dark ? AppColors.white : AppColors.lightTextPrimary;

    final subColor = dark
        ? AppColors.white.withValues(alpha: 0.80)
        : AppColors.lightTextSecondary;

    final titleText = data.title ?? data.address;

    return Container(
      padding: EdgeInsets.all(
        compact ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mapThumbnail != null) ...[
            mapThumbnail!,
            SizedBox(
              width: compact ? AppSpacing.sm : AppSpacing.md,
            ),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------------------------------------------------------------
                // LOCATION TITLE + FLAG
                // -------------------------------------------------------------

                if (visibility.address)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titleText,
                          style: (compact
                                  ? AppTypography.caption
                                  : AppTypography.h3)
                              .copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.flagEmoji != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          data.flagEmoji!,
                          style: TextStyle(
                            fontSize: compact ? 12 : 16,
                          ),
                        ),
                      ],
                    ],
                  ),

                // -------------------------------------------------------------
                // STREET ADDRESS
                // -------------------------------------------------------------

                if (visibility.address && data.streetAddress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      data.streetAddress!,
                      style: AppTypography.stampLabel.copyWith(
                        color: subColor,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // -------------------------------------------------------------
                // LIVE COORDINATES
                // -------------------------------------------------------------

                if (visibility.coordinates && data.coordinates != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      data.coordinates!,
                      style: AppTypography.stampLabel.copyWith(
                        color: subColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // -------------------------------------------------------------
                // LIVE DATE / TIME
                // -------------------------------------------------------------

                if (visibility.dateTime && data.dateTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      data.dateTime!,
                      style: AppTypography.stampLabel.copyWith(
                        color: subColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // -------------------------------------------------------------
                // METADATA
                // -------------------------------------------------------------

                if (!compact && _hasVisibleMetadata)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 4,
                      children: [
                        // GPS accuracy is deliberately placed first because
                        // accuracy is important for a GPS-based camera.
                        if (visibility.accuracy && data.accuracy != null)
                          _MetaChip(
                            icon: Icons.gps_fixed_rounded,
                            label: data.accuracy!,
                            color: subColor,
                          ),

                        if (visibility.altitude && data.altitude != null)
                          _MetaChip(
                            icon: Icons.terrain_outlined,
                            label: data.altitude!,
                            color: subColor,
                          ),

                        if (visibility.weather && data.weather != null)
                          _MetaChip(
                            icon: Icons.wb_sunny_outlined,
                            label: data.weather!,
                            color: subColor,
                          ),

                        if (data.pressure != null)
                          _MetaChip(
                            icon: Icons.speed_outlined,
                            label: data.pressure!,
                            color: subColor,
                          ),

                        if (visibility.compass &&
                            data.compassDirection != null)
                          _MetaChip(
                            icon: Icons.explore_outlined,
                            label: data.compassDirection!,
                            color: subColor,
                          ),
                      ],
                    ),
                  ),

                // -------------------------------------------------------------
                // NOTE
                // -------------------------------------------------------------

                if (visibility.note &&
                    data.note != null &&
                    data.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                    ),
                    child: Text(
                      data.note!,
                      style: AppTypography.caption.copyWith(
                        color: subColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasVisibleMetadata {
    if (visibility.accuracy && data.accuracy != null) {
      return true;
    }

    if (visibility.altitude && data.altitude != null) {
      return true;
    }

    if (visibility.weather && data.weather != null) {
      return true;
    }

    if (data.pressure != null) {
      return true;
    }

    if (visibility.compass && data.compassDirection != null) {
      return true;
    }

    return false;
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
