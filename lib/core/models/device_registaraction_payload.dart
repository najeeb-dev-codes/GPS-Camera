
/// Mirrors the field table in FLUTTER_API_INTEGRATION_GUIDE.md exactly.
/// Only `installationId` is required by the backend — everything else is
/// best-effort and sent as `null` when it isn't available yet (e.g.
/// `fcmToken` until Firebase is added, or `latitude`/`longitude` before
/// location permission is granted).
class DeviceRegistrationPayload {
  const DeviceRegistrationPayload({
    required this.installationId,
    this.firebaseInstallationId,
    this.hardwareId,
    this.fcmToken,
    this.deviceManufacturer,
    this.deviceBrand,
    this.deviceModel,
    this.deviceCode,
    this.cpuArchitecture,
    this.platform,
    this.osVersion,
    this.sdkVersion,
    this.appVersion,
    this.appBuildNumber,
    this.screenResolution,
    this.language,
    this.timezone,
    this.permissions,
    this.permissionsStatus,
    this.notificationStatus,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.countryCode,
  });

  final String installationId;
  final String? firebaseInstallationId;
  final String? hardwareId;
  final String? fcmToken;
  final String? deviceManufacturer;
  final String? deviceBrand;
  final String? deviceModel;
  final String? deviceCode;
  final String? cpuArchitecture;
  final String? platform;
  final String? osVersion;
  final int? sdkVersion;
  final String? appVersion;
  final int? appBuildNumber;
  final String? screenResolution;
  final String? language;
  final String? timezone;
  final Map<String, String>? permissions;
  final String? permissionsStatus;
  final String? notificationStatus;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'installation_id': installationId,
      'firebase_installation_id': firebaseInstallationId,
      'hardware_id': hardwareId,
      'fcm_token': fcmToken,
      'device_manufacturer': deviceManufacturer,
      'device_brand': deviceBrand,
      'device_model': deviceModel,
      'device_code': deviceCode,
      'cpu_architecture': cpuArchitecture,
      'platform': platform,
      'os_version': osVersion,
      'sdk_version': sdkVersion,
      'app_version': appVersion,
      'app_build_number': appBuildNumber,
      'screen_resolution': screenResolution,
      'language': language,
      'timezone': timezone,
      'permissions': permissions,
      'permissions_status': permissionsStatus,
      'notification_status': notificationStatus,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'country_code': countryCode,
    };
  }
}