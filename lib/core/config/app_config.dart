class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // BUILD-TIME OVERRIDE
  // ---------------------------------------------------------------------------

  /// Optional API URL supplied using --dart-define.
  ///
  /// Example:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
  ///
  /// When provided, this URL takes priority.
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Optional version API host supplied using --dart-define.
  ///
  /// Example:
  /// --dart-define=APP_VERSION_BASE_URL=https://example.com
  static const String _overrideAppVersionBaseUrl = String.fromEnvironment(
    'APP_VERSION_BASE_URL',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // ENVIRONMENT
  // ---------------------------------------------------------------------------

  /// Optional environment supplied using --dart-define.
  ///
  /// Production:
  /// flutter run --dart-define=ENV=prod
  ///
  /// Local development:
  /// flutter run --dart-define=ENV=dev
  ///
  /// When ENV is not supplied, the live production server is used.
  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: '',
  );

  static bool get isProd {
    final environment = _env.trim().toLowerCase();

    if (environment == 'dev' || environment == 'development') {
      return false;
    }

    // Production is the default for debug, profile and release builds.
    return true;
  }

  // ---------------------------------------------------------------------------
  // PRODUCTION SERVER
  // ---------------------------------------------------------------------------

  static const String _prodBaseUrl =
      'https://mobileapps.raiyaaninfotech.in/';

  /// App-version API host supplied by the backend team.
  static const String _prodAppVersionBaseUrl =
      'https://mobileapps.raiyaaninfotech.in/';

  // ---------------------------------------------------------------------------
  // DEVELOPMENT SERVER
  // ---------------------------------------------------------------------------

  /// Local backend computer's Wi-Fi IPv4 address.
  ///
  /// This is used only when running with:
  /// --dart-define=ENV=dev
  static const String _lanDevIp = '192.168.1.36';

  static const String _devPort = '8000';

  // ---------------------------------------------------------------------------
  // BASE URL
  // ---------------------------------------------------------------------------

  static final String baseUrl = _resolveBaseUrl();
  static final String appVersionBaseUrl = _resolveAppVersionBaseUrl();

  static String _resolveBaseUrl() {
    final overrideUrl = _overrideBaseUrl.trim();

    // Explicit API_BASE_URL has the highest priority.
    if (overrideUrl.isNotEmpty) {
      return _stripTrailingSlash(overrideUrl);
    }

    // Use the local backend only when ENV=dev is explicitly supplied.
    if (!isProd) {
      return 'http://$_lanDevIp:$_devPort';
    }

    // Default to the live production backend.
    return _stripTrailingSlash(_prodBaseUrl);
  }

  static String _resolveAppVersionBaseUrl() {
    final overrideUrl = _overrideAppVersionBaseUrl.trim();
    if (overrideUrl.isNotEmpty) {
      return _stripTrailingSlash(overrideUrl);
    }

    // Local development can serve every endpoint from the same host.
    if (!isProd) return baseUrl;

    return _stripTrailingSlash(_prodAppVersionBaseUrl);
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String _stripTrailingSlash(String url) {
    var normalizedUrl = url.trim();

    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(
        0,
        normalizedUrl.length - 1,
      );
    }

    return normalizedUrl;
  }
}
