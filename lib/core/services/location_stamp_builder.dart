import '../../shared/widgets/widgets.dart';
import 'location_service.dart';

/// Converts a live [LocationSnapshot] plus timestamp into the [GpsStampData]
/// rendered by [GpsStampOverlay].
///
/// Intended live camera format:
///   Tirunelveli, Tamil Nadu, India 🇮🇳
///   W Car St, Tirunelveli, Tamil Nadu 627006, India
///   Lat 8.727448° Long 77.686064°
///   Tuesday, 25/08/2026 04:05 PM
///   GPS ±3 m   Altitude 47 m
class LocationStampBuilder {
  LocationStampBuilder._();

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static GpsStampData build({
    required LocationSnapshot? snapshot,
    required DateTime capturedAt,
    String? note,
  }) {
    return GpsStampData(
      address: _formatTitle(snapshot),
      title: _formatTitle(snapshot),
      flagEmoji: _flagEmoji(snapshot?.countryCode),
      streetAddress: _formatStreetAddress(snapshot),
      coordinates: _formatCoordinates(snapshot),
      dateTime: _formatDateTime(capturedAt),
      accuracy: _formatAccuracy(snapshot),
      altitude: _formatAltitude(snapshot),

      // No live data source is wired for these yet.
      weather: null,
      pressure: null,
      compassDirection: _formatCompass(snapshot?.heading),
      note: note,
    );
  }

  static String? _formatCompass(double? heading) {
    if (heading == null || !heading.isFinite || heading < 0) return null;
    const directions = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = heading % 360;
    final index = ((normalized + 22.5) ~/ 45) % directions.length;
    return '${directions[index]} ${normalized.round()}°';
  }

  // ---------------------------------------------------------------------------
  // TITLE — "City, State, Country"
  // ---------------------------------------------------------------------------

  static String _formatTitle(LocationSnapshot? snapshot) {
    if (snapshot == null) {
      return 'Locating…';
    }

    final parts = <String>[
      if (_hasValue(snapshot.city)) snapshot.city!.trim(),
      if (_hasValue(snapshot.state)) snapshot.state!.trim(),
      if (_hasValue(snapshot.country)) snapshot.country!.trim(),
    ];

    if (parts.isEmpty) {
      if (snapshot.latitude != null && snapshot.longitude != null) {
        return 'Current location';
      }

      return 'Location unavailable';
    }

    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // FULL STREET ADDRESS
  // ---------------------------------------------------------------------------

  static String? _formatStreetAddress(LocationSnapshot? snapshot) {
    if (snapshot == null) {
      return null;
    }

    final parts = <String>[];

    _addUnique(parts, snapshot.street);
    _addUnique(parts, snapshot.subLocality);
    _addUnique(parts, snapshot.city);

    if (_hasValue(snapshot.state)) {
      final state = snapshot.state!.trim();
      final postalCode = snapshot.postalCode?.trim();

      _addUnique(
        parts,
        _hasValue(postalCode) ? '$state $postalCode' : state,
      );
    } else {
      _addUnique(parts, snapshot.postalCode);
    }

    _addUnique(parts, snapshot.country);

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // COORDINATES — "Lat 8.727448° Long 77.686064°"
  // ---------------------------------------------------------------------------

  static String? _formatCoordinates(LocationSnapshot? snapshot) {
    final latitude = snapshot?.latitude;
    final longitude = snapshot?.longitude;

    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite) {
      return null;
    }

    return 'Lat ${latitude.toStringAsFixed(6)}° '
        'Long ${longitude.toStringAsFixed(6)}°';
  }

  // ---------------------------------------------------------------------------
  // GPS ACCURACY — "GPS ±3 m"
  // ---------------------------------------------------------------------------

  static String? _formatAccuracy(LocationSnapshot? snapshot) {
    final accuracy = snapshot?.accuracy;

    if (accuracy == null ||
        !accuracy.isFinite ||
        accuracy < 0) {
      return null;
    }

    if (accuracy < 10) {
      return 'GPS ±${accuracy.toStringAsFixed(1)} m';
    }

    return 'GPS ±${accuracy.round()} m';
  }

  // ---------------------------------------------------------------------------
  // ALTITUDE — "Altitude 47 m"
  // ---------------------------------------------------------------------------

  static String? _formatAltitude(LocationSnapshot? snapshot) {
    final altitude = snapshot?.altitude;

    if (altitude == null || !altitude.isFinite) {
      return null;
    }

    return 'Altitude ${altitude.round()} m';
  }

  // ---------------------------------------------------------------------------
  // DATE / TIME — "Tuesday, 25/08/2026 04:05 PM"
  // ---------------------------------------------------------------------------

  static String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final weekday = _weekdays[local.weekday - 1];
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    // Seconds are intentionally included so the camera stamp is visibly live.
    return '$weekday, $day/$month/$year $hour:$minute:$second $period';
  }

  // ---------------------------------------------------------------------------
  // COUNTRY FLAG EMOJI
  // ---------------------------------------------------------------------------

  static String? _flagEmoji(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) {
      return null;
    }

    final code = countryCode.toUpperCase();
    const base = 0x1F1E6;
    const asciiA = 0x41;

    final first = code.codeUnitAt(0);
    final second = code.codeUnitAt(1);

    if (first < asciiA || first > asciiA + 25) {
      return null;
    }

    if (second < asciiA || second > asciiA + 25) {
      return null;
    }

    return String.fromCharCode(base + (first - asciiA)) +
        String.fromCharCode(base + (second - asciiA));
  }

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static void _addUnique(List<String> parts, String? value) {
    if (!_hasValue(value)) {
      return;
    }

    final cleaned = value!.trim();

    final alreadyExists = parts.any(
      (item) => item.toLowerCase() == cleaned.toLowerCase(),
    );

    if (!alreadyExists) {
      parts.add(cleaned);
    }
  }
}
