
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // BUILD-TIME OVERRIDE
  // ---------------------------------------------------------------------------

  /// Optional complete API URL provided using --dart-define.
  ///
  /// Example:
  ///
  /// flutter run \
  ///   --dart-define=API_BASE_URL=http://192.168.1.50:8000
  ///
  /// If provided, this always takes priority.
  static const String _overrideBaseUrl =
      String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // ENVIRONMENT
  // ---------------------------------------------------------------------------

  /// Set ENV=prod for production builds.
  static const String _env =
      String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isProd => _env == 'prod';

  // ---------------------------------------------------------------------------
  // PRODUCTION SERVER
  // ---------------------------------------------------------------------------

  /// Replace this before production release.
  static const String _prodBaseUrl =
      'https://yourdomain.com';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT SERVER
  // ---------------------------------------------------------------------------

  /// Backend PC Wi-Fi IPv4 address.
  ///
  /// Your physical phone must be connected to the same network.
  static const String _lanDevIp =
      '192.168.1.36';

  /// Backend server port.
  static const String _devPort =
      '8000';

  // ---------------------------------------------------------------------------
  // BASE URL
  // ---------------------------------------------------------------------------

  /// Final API base URL used throughout the application.
  static final String baseUrl =
      _resolveBaseUrl();

  static String _resolveBaseUrl() {
    // 1. Explicit dart-define takes highest priority.
    if (_overrideBaseUrl.trim().isNotEmpty) {
      return _stripTrailingSlash(
        _overrideBaseUrl.trim(),
      );
    }

    // 2. Production environment.
    if (isProd) {
      return _stripTrailingSlash(
        _prodBaseUrl,
      );
    }

    // 3. Development physical device.
    return 'http://$_lanDevIp:$_devPort';
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String _stripTrailingSlash(
    String url,
  ) {
    while (url.endsWith('/')) {
      url = url.substring(
        0,
        url.length - 1,
      );
    }

    return url;
  }
}