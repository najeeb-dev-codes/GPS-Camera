import '../../shared/widgets/widgets.dart';

/// Central place for the "current capture" location data every screen in
/// the camera → preview → save → gallery → details chain needs to agree
/// on. Swap [current] for a real GPS/location-service read later — every
/// screen already only reads from here, so nothing else needs to change.
class SampleLocationData {
  SampleLocationData._();

  static GpsStampData current = const GpsStampData(
    address: 'Palayamkottai, Tirunelveli, Tamil Nadu',
    coordinates: '8.7281° N, 77.7081° E',
    dateTime: '18 Aug 2026 - 04:25 PM',
    weather: '28°C',
    pressure: '1021 hPa',
    altitude: '16 m',
  );

  static const String capturedImageAsset =
      'assets/images/captures/site_inspection.jpg';
}