class MapsConfig {
  MapsConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsApiKey =>
      googleMapsApiKey.trim().isNotEmpty;

  static Uri? staticMapUri({
    required double? latitude,
    required double? longitude,
    int width = 320,
    int height = 320,
    int zoom = 17,
    String mapType = 'hybrid',
  }) {
    if (!hasGoogleMapsApiKey ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    final coordinates = '$latitude,$longitude';

    return Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      <String, String>{
        'center': coordinates,
        'zoom': zoom.toString(),
        'size':
            '${width.clamp(1, 640)}x${height.clamp(1, 640)}',
        'scale': '2',
        'maptype': mapType,
        'markers': 'color:red|$coordinates',
        'key': googleMapsApiKey,
      },
    );
  }

  static String locationUrl({
    required double? latitude,
    required double? longitude,
    required String fallbackAddress,
  }) {
    final query = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : fallbackAddress;

    return Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{
        'api': '1',
        'query': query,
      },
    ).toString();
  }
}