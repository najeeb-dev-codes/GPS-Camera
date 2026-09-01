import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../shared/widgets/widgets.dart';

/// Keeps the camera stamp live while the camera screen is open.
///
/// - Coordinates / GPS accuracy / altitude update from the live position stream.
/// - Address is reverse-geocoded periodically instead of on every tiny GPS fix.
/// - Date/time is refreshed every second even when the phone is not moving.
/// - [freeze] returns the exact stamp that should be attached to a captured photo.
class LiveLocationService {
  LiveLocationService();

  final StreamController<GpsStampData> _controller =
      StreamController<GpsStampData>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _clockTimer;

  Position? _latestPosition;
  Placemark? _latestPlacemark;
  GpsStampData? _latestData;

  DateTime? _lastGeocodeAt;
  Position? _lastGeocodedPosition;

  bool _isStarting = false;

  Stream<GpsStampData> get stream => _controller.stream;
  GpsStampData? get latestData => _latestData;

  Future<void> start() async {
    if (_controller.isClosed || _isStarting) return;

    _isStarting = true;

    try {
      await stopListeningOnly();

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Please turn on device location/GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it in app settings.',
        );
      }

      // Get a fresh high-accuracy fix as soon as the camera opens.
      try {
        final firstPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 15),
          ),
        );

        await _handlePosition(firstPosition, forceGeocode: true);
      } catch (e) {
        debugPrint('Initial live GPS fix failed: $e');

        // Only use cached location as a fallback while waiting for stream data.
        final cached = await Geolocator.getLastKnownPosition();
        if (cached != null) {
          await _handlePosition(cached, forceGeocode: true);
        }
      }

      // Keep GPS values live while the phone moves.
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          unawaited(_handlePosition(position));
        },
        onError: (Object error) {
          debugPrint('Live GPS stream error: $error');
        },
      );

      // Keep the visible clock live even if GPS sends no new position.
      _clockTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _emitCurrentData(),
      );
    } finally {
      _isStarting = false;
    }
  }

  Future<GpsStampData> getCurrentStampData() async {
    if (_latestData != null) {
      return freeze(DateTime.now());
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 15),
      ),
    );

    await _handlePosition(position, forceGeocode: true);

    if (_latestData == null) {
      throw Exception('Unable to read current GPS location.');
    }

    return freeze(DateTime.now());
  }

  /// Freezes the latest GPS values and changes only the time to the exact
  /// shutter time. The preview therefore keeps the same stamp after capture.
  GpsStampData freeze(DateTime capturedAt) {
    final data = _latestData;

    if (data == null) {
      return GpsStampData(
        address: 'Location unavailable',
        dateTime: formatDateTime(capturedAt),
      );
    }

    return data.copyWith(
      dateTime: formatDateTime(capturedAt),
    );
  }

  Future<void> _handlePosition(
    Position position, {
    bool forceGeocode = false,
  }) async {
    _latestPosition = position;

    // Emit GPS values immediately. The previous address is retained until the
    // reverse-geocode call completes.
    _emitCurrentData();

    final now = DateTime.now();

    final movedEnough = _lastGeocodedPosition == null
        ? true
        : Geolocator.distanceBetween(
              _lastGeocodedPosition!.latitude,
              _lastGeocodedPosition!.longitude,
              position.latitude,
              position.longitude,
            ) >=
            5;

    final geocodeOld = _lastGeocodeAt == null
        ? true
        : now.difference(_lastGeocodeAt!).inSeconds >= 10;

    if (forceGeocode || movedEnough || geocodeOld) {
      await _reverseGeocode(position);
      _emitCurrentData();
    }
  }

  Future<void> _reverseGeocode(Position position) async {
    try {
      final Geocoding _geocoding = Geocoding();

final placemarks = await _geocoding.placemarkFromCoordinates(
  position.latitude,
  position.longitude,
);

      if (placemarks.isNotEmpty) {
        _latestPlacemark = placemarks.first;
        _lastGeocodedPosition = position;
        _lastGeocodeAt = DateTime.now();
      }
    } catch (e) {
      // GPS coordinates/accuracy still continue even if address lookup fails.
      debugPrint('Reverse geocode error: $e');
    }
  }

  void _emitCurrentData() {
    final position = _latestPosition;
    if (position == null || _controller.isClosed) return;

    final placemark = _latestPlacemark;

    final street = _firstNonEmpty(<String?>[
      _joinNonEmpty(<String?>[
        placemark?.subThoroughfare,
        placemark?.thoroughfare,
      ]),
      placemark?.street,
      placemark?.name,
    ]);

    final area = _firstNonEmpty(<String?>[
      placemark?.subLocality,
    ]);

    final city = _firstNonEmpty(<String?>[
      placemark?.locality,
      placemark?.subAdministrativeArea,
    ]);

    final state = _clean(placemark?.administrativeArea);
    final country = _clean(placemark?.country);
    final countryCode = _clean(placemark?.isoCountryCode);
    final postalCode = _clean(placemark?.postalCode);

    final title = _joinUnique(<String?>[
      city,
      state,
      country,
    ]);

    final streetAddress = _joinAddress(
      street: street,
      area: area,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
    );

    final fallbackAddress = streetAddress ??
        title ??
        'Lat ${position.latitude.toStringAsFixed(6)}, '
            'Lng ${position.longitude.toStringAsFixed(6)}';

    final accuracy = position.accuracy < 10
        ? 'GPS ±${position.accuracy.toStringAsFixed(1)} m'
        : 'GPS ±${position.accuracy.round()} m';

    final altitude = 'Altitude ${position.altitude.round()} m';

    final data = GpsStampData(
      address: fallbackAddress,
      title: title,
      flagEmoji: _flagEmoji(countryCode),
      streetAddress: streetAddress,
      latitude: position.latitude,
      longitude: position.longitude,
      street: street,
      area: area,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      coordinates: formatCoordinates(position.latitude, position.longitude),
      dateTime: formatDateTime(DateTime.now()),
      accuracy: accuracy,
      altitude: altitude,
      compassDirection: _formatCompass(position.heading),
    );

    _latestData = data;
    _controller.add(data);
  }

  static String formatCoordinates(double latitude, double longitude) {
    return 'Lat ${latitude.toStringAsFixed(6)}° '
        'Long ${longitude.toStringAsFixed(6)}°';
  }

  static String? _formatCompass(double heading) {
    if (!heading.isFinite || heading < 0) return null;
    const directions = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = heading % 360;
    final index = ((normalized + 22.5) ~/ 45) % directions.length;
    return '${directions[index]} ${normalized.round()}°';
  }

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();

    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '${weekdays[local.weekday - 1]}, '
        '$day/$month/${local.year} '
        '$hour:$minute:$second $period';
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final cleaned = _clean(value);
      if (cleaned != null) return cleaned;
    }
    return null;
  }

  static String? _joinNonEmpty(List<String?> values) {
    final parts = values
        .map(_clean)
        .whereType<String>()
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String? _joinUnique(List<String?> values) {
    final parts = <String>[];
    for (final value in values) {
      final cleaned = _clean(value);
      if (cleaned == null) continue;
      if (!parts.any((v) => v.toLowerCase() == cleaned.toLowerCase())) {
        parts.add(cleaned);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _joinAddress({
    required String? street,
    required String? area,
    required String? city,
    required String? state,
    required String? postalCode,
    required String? country,
  }) {
    final parts = <String>[];

    void add(String? value) {
      final cleaned = _clean(value);
      if (cleaned == null) return;
      if (!parts.any((v) => v.toLowerCase() == cleaned.toLowerCase())) {
        parts.add(cleaned);
      }
    }

    add(street);
    add(area);
    add(city);

    final stateWithPostal = state == null
        ? postalCode
        : postalCode == null
            ? state
            : '$state $postalCode';

    add(stateWithPostal);
    add(country);

    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _flagEmoji(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) return null;

    final code = countryCode.toUpperCase();
    const regionalIndicatorOffset = 0x1F1E6 - 0x41;

    final first = code.codeUnitAt(0);
    final second = code.codeUnitAt(1);

    if (first < 0x41 || first > 0x5A || second < 0x41 || second > 0x5A) {
      return null;
    }

    return String.fromCharCode(first + regionalIndicatorOffset) +
        String.fromCharCode(second + regionalIndicatorOffset);
  }

  Future<void> stopListeningOnly() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _clockTimer?.cancel();
    _clockTimer = null;
  }

  Future<void> dispose() async {
    await stopListeningOnly();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
