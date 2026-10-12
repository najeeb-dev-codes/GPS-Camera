import 'package:flutter/material.dart';

import '../../../core/services/captured_photo_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

/// Shows only the location information for a captured photo.
///
/// The Information screen uses the location data already stored in
/// [GpsStampData]. The stamp type does not affect how the information is
/// displayed, so Map, Address, Time & Place and Minimal stamps all use the
/// same street/area extraction here.
class PhotoInformationPanel extends StatelessWidget {
  const PhotoInformationPanel({
    super.key,
    required this.photo,
    required this.stampData,
  });

  final CapturedPhoto? photo;
  final GpsStampData stampData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppTopBar(title: 'Information'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
                children: [
                  _InformationSection(
                    title: 'Location',
                    children: [
                      _InformationRow(
                        label: 'Date & time',
                        value: stampData.dateTime,
                      ),
                      _InformationRow(
                        label: 'Coordinates',
                        value: stampData.coordinates ??
                            _formatCoordinates(
                              stampData.latitude,
                              stampData.longitude,
                            ),
                      ),
                      _InformationRow(
                        label: 'Street',
                        value: _streetName(stampData),
                      ),
                      _InformationRow(
                        label: 'Area',
                        value: _areaName(stampData),
                      ),
                      _InformationRow(
                        label: 'City',
                        value: stampData.city,
                      ),
                      _InformationRow(
                        label: 'State',
                        value: stampData.state,
                      ),
                      _InformationRow(
                        label: 'Country',
                        value: stampData.country,
                      ),
                      _InformationRow(
                        label: 'Postal code',
                        value: stampData.postalCode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const AdBannerWidget(
              format: AdDisplayFormat.mediumRectangle,
              reserveSpaceWhileLoading: true,
              slotHeight: 250,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  /// Returns the door number together with the actual street name.
  ///
  /// Some stamp types store only the door number in [street], while the
  /// complete reverse-geocoded address is available in [streetAddress].
  /// Keep both the door number and street name in the Street row.
  static String? _streetName(GpsStampData data) {
    final parts = _addressParts(data.streetAddress);

    // Typical reverse-geocoded order is: door number, street, area, city,
    // state, country. When the first component is only the door number,
    // combine it with the following street-name component.
    if (parts.length > 1 && _isDoorNumber(parts.first)) {
      final streetPart = parts[1];
      if (_looksLikeStreetName(streetPart) &&
          !_isAdministrativePart(streetPart, data)) {
        return '${parts.first}, $streetPart';
      }
    }

    // Some geocoders already return "door number street name" as one
    // component. Keep it exactly as the street value.
    if (parts.isNotEmpty && _looksLikeStreetName(parts.first)) {
      return parts.first;
    }

    // Fallback for saved data where streetAddress was not stored.
    final street = data.street?.trim();
    if (street != null && street.isNotEmpty) {
      final streetParts = _addressParts(street);

      if (streetParts.length > 1 && _isDoorNumber(streetParts.first)) {
        final streetPart = streetParts[1];
        if (_looksLikeStreetName(streetPart) &&
            !_isAdministrativePart(streetPart, data)) {
          return '${streetParts.first}, $streetPart';
        }
      }

      if (streetParts.isNotEmpty &&
          _looksLikeStreetName(streetParts.first)) {
        return streetParts.first;
      }

      return street;
    }

    return null;
  }

  /// Gets the area/locality. If the structured [area] field is missing,
  /// recover it from the reverse-geocoded address without changing the data.
  static String? _areaName(GpsStampData data) {
    final area = data.area?.trim();
    if (area != null && area.isNotEmpty) return area;

    final parts = _addressParts(data.streetAddress);
    if (parts.length > 2) {
      final candidate = parts[2];
      if (!_isAdministrativePart(candidate, data)) {
        return candidate;
      }
    }

    // Some geocoders omit the door number from streetAddress. In that case
    // the area is normally the component immediately after the street name.
    if (parts.length > 1 && _looksLikeStreetName(parts.first)) {
      final candidate = parts[1];
      if (!_isAdministrativePart(candidate, data)) {
        return candidate;
      }
    }

    return null;
  }

  static List<String> _addressParts(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return const <String>[];

    return raw
        .split(RegExp(r'\s*,\s*'))
        .map((part) => _cleanAddressPart(part))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String _cleanAddressPart(String value) {
    return value.trim().replaceAll(RegExp(r'^[-–—•]+\s*'), '');
  }

  static bool _isDoorNumber(String value) {
    final text = value.trim();
    return RegExp(
      r'^\d+[A-Za-z]?(?:[-/]\d+[A-Za-z]?)?$',
    ).hasMatch(text);
  }

  static bool _looksLikeStreetName(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return false;

    // A value containing letters is normally a street/locality name. A value
    // made only from a house/door number must not be shown as the Street row.
    return RegExp(r'[A-Za-z]').hasMatch(text);
  }

  static bool _isAdministrativePart(String value, GpsStampData data) {
    final candidate = value.trim().toLowerCase();
    if (candidate.isEmpty) return true;

    final knownValues = <String?>[
      data.area,
      data.city,
      data.state,
      data.country,
      data.postalCode,
    ];

    return knownValues.any(
      (known) =>
          known != null &&
          known.trim().isNotEmpty &&
          known.trim().toLowerCase() == candidate,
    );
  }

  static String _formatCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return '—';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    final displayValue = text == null || text.isEmpty ? '—' : text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
