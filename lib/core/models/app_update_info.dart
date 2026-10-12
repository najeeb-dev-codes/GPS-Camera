/// Version information returned by the app-version API.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.clientVersion,
    required this.currentVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.isUpdateAvailable,
    required this.updateTitle,
    required this.updateMessage,
    required this.storeUrl,
  });

  factory AppUpdateInfo.fromJson(
    Map<String, dynamic> json, {
    required String platform,
  }) {
    final platformStoreUrl = platform == 'ios'
        ? _readString(json['app_store_url'])
        : _readString(json['play_store_url']);

    return AppUpdateInfo(
      clientVersion: _readString(json['client_version']),
      currentVersion: _readString(json['current_version']),
      minimumVersion: _readString(json['minimum_version']),
      forceUpdate: _readBool(json['force_update']),
      isUpdateAvailable: _readBool(json['is_update_available']),
      updateTitle: _readString(
        json['update_title'],
        fallback: 'Update Required',
      ),
      updateMessage: _readString(
        json['update_message'],
        fallback: 'Please update the app to continue.',
      ),
      storeUrl: _readString(
        json['store_url'],
        fallback: platformStoreUrl,
      ),
    );
  }

  final String clientVersion;
  final String currentVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final bool isUpdateAvailable;
  final String updateTitle;
  final String updateMessage;
  final String storeUrl;

  static String _readString(
    Object? value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
}
