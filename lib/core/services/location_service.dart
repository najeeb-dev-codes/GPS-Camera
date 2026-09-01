import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final Geocoding _geocoding = Geocoding();

  /// We don't want to reverse-geocode the address for every tiny GPS change.
  ///
  /// Latitude / longitude / accuracy can update continuously.
  /// Address will refresh only after the user has moved this distance.
  static const double addressRefreshDistanceMeters = 5.0;

  // ===========================================================================
  // CHECK WHETHER LOCATION CAN BE USED
  // ===========================================================================

  static Future<bool> canUseLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          'LocationService: device location service is disabled.',
        );
        return false;
      }

      final permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
          'LocationService: location permission is not granted.',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint(
        'LocationService.canUseLocation failed: $e',
      );

      return false;
    }
  }

  // ===========================================================================
  // GET FRESH HIGH-ACCURACY POSITION
  // ===========================================================================

  /// Gets a fresh GPS fix.
  ///
  /// IMPORTANT:
  /// We deliberately do NOT call getLastKnownPosition() here.
  ///
  /// For a GPS-camera app, freshness is more important than immediately
  /// showing an old cached location.
  static Future<Position?> getFreshPosition() async {
    try {
      final canUse = await canUseLocation();

      if (!canUse) {
        return null;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );

      debugPrint(
        'Fresh GPS fix: '
        '${position.latitude}, '
        '${position.longitude} '
        'accuracy=${position.accuracy}m '
        'altitude=${position.altitude}m',
      );

      return position;
    } on TimeoutException {
      debugPrint(
        'LocationService: fresh GPS request timed out.',
      );

      return null;
    } catch (e) {
      debugPrint(
        'LocationService.getFreshPosition failed: $e',
      );

      return null;
    }
  }

  // ===========================================================================
  // LIVE HIGH-ACCURACY GPS STREAM
  // ===========================================================================

  /// Continuously emits updated GPS positions while the camera is open.
  ///
  /// distanceFilter: 1
  /// means Android should notify us after approximately one metre of movement.
  ///
  /// The actual rate/accuracy still depends on:
  /// - GPS signal
  /// - Android device
  /// - indoor/outdoor environment
  /// - battery optimisation
  /// - Google Play Services / device location provider
  static Stream<Position> positionStream() {
    const settings = LocationSettings(
      accuracy:
          LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    return Geolocator.getPositionStream(
      locationSettings: settings,
    );
  }

  // ===========================================================================
  // CONVERT POSITION INTO SNAPSHOT
  // ===========================================================================

  /// Creates a location snapshot immediately from GPS coordinates.
  ///
  /// Address fields can optionally be supplied from a previous
  /// reverse-geocoding result.
  static LocationSnapshot snapshotFromPosition(
    Position position, {
    LocationSnapshot? addressSource,
  }) {
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,

      // GPS quality
      accuracy: position.accuracy,

      // Altitude
      altitude: position.altitude,
      altitudeAccuracy:
          position.altitudeAccuracy,

      // Movement / direction
      heading: position.heading,
      headingAccuracy:
          position.headingAccuracy,
      speed: position.speed,
      speedAccuracy:
          position.speedAccuracy,

      timestamp: position.timestamp,

      // Preserve previous address until we reverse-geocode again.
      street: addressSource?.street,
      subLocality:
          addressSource?.subLocality,
      city: addressSource?.city,
      state: addressSource?.state,
      postalCode:
          addressSource?.postalCode,
      country: addressSource?.country,
      countryCode:
          addressSource?.countryCode,
    );
  }

  // ===========================================================================
  // ADD ADDRESS TO SNAPSHOT
  // ===========================================================================

  static Future<LocationSnapshot>
      addAddress(
    LocationSnapshot snapshot,
  ) async {
    final latitude = snapshot.latitude;
    final longitude = snapshot.longitude;

    if (latitude == null ||
        longitude == null) {
      return snapshot;
    }

    final placemark =
        await _reverseGeocode(
      latitude,
      longitude,
    );

    return snapshot.copyWith(
      street: placemark.street,
      subLocality:
          placemark.subLocality,
      city: placemark.city,
      state: placemark.state,
      postalCode:
          placemark.postalCode,
      country: placemark.country,
      countryCode:
          placemark.countryCode,
    );
  }

  // ===========================================================================
  // INITIAL CAMERA LOCATION
  // ===========================================================================

  /// Used when the live camera first opens.
  ///
  /// Flow:
  ///
  /// Fresh GPS
  ///   ↓
  /// latitude / longitude / accuracy / altitude
  ///   ↓
  /// reverse geocode
  ///   ↓
  /// full location snapshot
  static Future<LocationSnapshot>
      captureFresh() async {
    final position =
        await getFreshPosition();

    if (position == null) {
      return const LocationSnapshot();
    }

    var snapshot =
        snapshotFromPosition(position);

    snapshot =
        await addAddress(snapshot);

    return snapshot;
  }

  // ===========================================================================
  // DISTANCE BETWEEN TWO SNAPSHOTS
  // ===========================================================================

  static double distanceBetweenSnapshots(
    LocationSnapshot from,
    LocationSnapshot to,
  ) {
    final fromLatitude =
        from.latitude;
    final fromLongitude =
        from.longitude;
    final toLatitude =
        to.latitude;
    final toLongitude =
        to.longitude;

    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  // ===========================================================================
  // REVERSE GEOCODING
  // ===========================================================================

  static Future<_Placemark>
      _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks =
          await _geocoding
              .placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint(
          'LocationService: no placemark found.',
        );

        return const _Placemark();
      }

      final placemark =
          placemarks.first;

      debugPrint(
        'Reverse geocode: '
        '${placemark.street}, '
        '${placemark.locality}, '
        '${placemark.administrativeArea}, '
        '${placemark.country}',
      );

      return _Placemark(
        street: _firstNonEmpty([
          _joinNonEmpty([
            placemark.subThoroughfare,
            placemark.thoroughfare,
          ]),
          placemark.street,
          placemark.name,
        ]),
        subLocality:
            _firstNonEmpty([
          placemark.subLocality,
        ]),
        city: _firstNonEmpty([
          placemark.locality,
          placemark
              .subAdministrativeArea,
        ]),
        state: _firstNonEmpty([
          placemark
              .administrativeArea,
        ]),
        postalCode:
            _firstNonEmpty([
          placemark.postalCode,
        ]),
        country:
            _firstNonEmpty([
          placemark.country,
        ]),
        countryCode:
            _firstNonEmpty([
          placemark.isoCountryCode,
        ]),
      );
    } catch (e) {
      debugPrint(
        'LocationService._reverseGeocode failed: $e',
      );

      return const _Placemark();
    }
  }

  // ===========================================================================
  // STRING HELPERS
  // ===========================================================================

  static String? _firstNonEmpty(
    List<String?> values,
  ) {
    for (final value in values) {
      if (value != null &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static String? _joinNonEmpty(
    List<String?> values, {
    String separator = ' ',
  }) {
    final parts = values
        .where(
          (value) =>
              value != null &&
              value.trim().isNotEmpty,
        )
        .map(
          (value) =>
              value!.trim(),
        )
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(separator);
  }
}

// =============================================================================
// INTERNAL PLACEMARK MODEL
// =============================================================================

class _Placemark {
  const _Placemark({
    this.street,
    this.subLocality,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.countryCode,
  });

  final String? street;
  final String? subLocality;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? countryCode;
}

// =============================================================================
// PUBLIC LOCATION SNAPSHOT
// =============================================================================

class LocationSnapshot {
  const LocationSnapshot({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.timestamp,
    this.street,
    this.subLocality,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.countryCode,
  });

  // ---------------------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------------------

  final double? latitude;
  final double? longitude;

  /// Horizontal location accuracy in metres.
  ///
  /// Example:
  /// 3.5 means approximately ±3.5 metres.
  final double? accuracy;

  // ---------------------------------------------------------------------------
  // ALTITUDE
  // ---------------------------------------------------------------------------

  final double? altitude;

  /// Vertical altitude accuracy in metres when supported by the device.
  final double? altitudeAccuracy;

  // ---------------------------------------------------------------------------
  // MOVEMENT / DIRECTION
  // ---------------------------------------------------------------------------

  final double? heading;
  final double? headingAccuracy;

  /// Speed in metres per second.
  final double? speed;

  final double? speedAccuracy;

  // ---------------------------------------------------------------------------
  // GPS FIX TIME
  // ---------------------------------------------------------------------------

  final DateTime? timestamp;

  // ---------------------------------------------------------------------------
  // ADDRESS
  // ---------------------------------------------------------------------------

  final String? street;
  final String? subLocality;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? countryCode;

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  LocationSnapshot copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? altitudeAccuracy,
    double? heading,
    double? headingAccuracy,
    double? speed,
    double? speedAccuracy,
    DateTime? timestamp,
    String? street,
    String? subLocality,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? countryCode,
  }) {
    return LocationSnapshot(
      latitude:
          latitude ?? this.latitude,
      longitude:
          longitude ?? this.longitude,
      accuracy:
          accuracy ?? this.accuracy,
      altitude:
          altitude ?? this.altitude,
      altitudeAccuracy:
          altitudeAccuracy ??
              this.altitudeAccuracy,
      heading:
          heading ?? this.heading,
      headingAccuracy:
          headingAccuracy ??
              this.headingAccuracy,
      speed:
          speed ?? this.speed,
      speedAccuracy:
          speedAccuracy ??
              this.speedAccuracy,
      timestamp:
          timestamp ?? this.timestamp,
      street:
          street ?? this.street,
      subLocality:
          subLocality ??
              this.subLocality,
      city:
          city ?? this.city,
      state:
          state ?? this.state,
      postalCode:
          postalCode ??
              this.postalCode,
      country:
          country ?? this.country,
      countryCode:
          countryCode ??
              this.countryCode,
    );
  }
}