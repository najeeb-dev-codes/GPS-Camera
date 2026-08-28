




import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_flow_service.dart';

/// Gathers everything the device-registration payload needs *except*
/// `installation_id` (that's owned by [InstallationIdService]) and
/// `fcm_token`/`firebase_installation_id` (null until Firebase is added).
///
/// Every getter here re-reads live state — nothing is cached — so calling
/// [collect] again after a permission changes or the user moves picks up
/// the latest values automatically, which is exactly what
/// DeviceRegistrationService wants at send-time.
class DeviceInfoCollector {
  DeviceInfoCollector._();

  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // ---------------------------------------------------------------------
  // DEVICE / APP FIELDS
  // ---------------------------------------------------------------------

  static Future<_StaticDeviceFields> collectStaticFields() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final locale = ui.PlatformDispatcher.instance.locale.toString();
    final timezone = DateTime.now().timeZoneName;
    final size = ui.PlatformDispatcher.instance.views.first.physicalSize;
    final screenResolution =
        '${size.width.round()}x${size.height.round()}';

    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return _StaticDeviceFields(
        hardwareId: info.id,
        deviceManufacturer: info.manufacturer,
        deviceBrand: info.brand,
        deviceModel: info.model,
        deviceCode: info.device,
        cpuArchitecture:
            info.supportedAbis.isNotEmpty ? info.supportedAbis.first : null,
        platform: 'Android',
        osVersion: 'Android ${info.version.release}',
        sdkVersion: info.version.sdkInt,
        appVersion: packageInfo.version,
        appBuildNumber: int.tryParse(packageInfo.buildNumber),
        screenResolution: screenResolution,
        language: locale,
        timezone: timezone,
      );
    }

    if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return _StaticDeviceFields(
        hardwareId: info.identifierForVendor,
        deviceManufacturer: 'Apple',
        deviceBrand: 'Apple',
        deviceModel: info.utsname.machine,
        deviceCode: info.utsname.machine,
        cpuArchitecture: 'arm64',
        platform: 'iOS',
        osVersion: 'iOS ${info.systemVersion}',
        sdkVersion: null,
        appVersion: packageInfo.version,
        appBuildNumber: int.tryParse(packageInfo.buildNumber),
        screenResolution: screenResolution,
        language: locale,
        timezone: timezone,
      );
    }

    // Fallback for any other platform (desktop/web) — best effort only.
    return _StaticDeviceFields(
      hardwareId: null,
      deviceManufacturer: null,
      deviceBrand: null,
      deviceModel: null,
      deviceCode: null,
      cpuArchitecture: null,
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      sdkVersion: null,
      appVersion: packageInfo.version,
      appBuildNumber: int.tryParse(packageInfo.buildNumber),
      screenResolution: screenResolution,
      language: locale,
      timezone: timezone,
    );
  }

  // ---------------------------------------------------------------------
  // PERMISSIONS SNAPSHOT
  // ---------------------------------------------------------------------

  /// Live permission map + a short human summary, rebuilt fresh every call.
  static Future<_PermissionFields> collectPermissionFields() async {
    final cameraGranted = await PermissionFlowService.isCameraGranted();
    final photosGranted = await PermissionFlowService.isPhotosGranted();
    final notificationGranted =
        await PermissionFlowService.isNotificationGranted();

    final locationStatus = await Permission.locationWhenInUse.status;
    final locationValue = _locationPermissionValue(locationStatus);

    final permissions = <String, String>{
      'camera': cameraGranted ? 'granted' : 'denied',
      'location': locationValue,
      'notifications': notificationGranted ? 'granted' : 'denied',
      'photos_media': photosGranted ? 'granted' : 'denied',
    };

    final grantedLabels = <String>[
      if (cameraGranted) 'Camera',
      if (locationValue != 'denied') 'Location',
      if (photosGranted) 'Photos',
      if (notificationGranted) 'Notifications',
    ];

    final permissionsStatus = grantedLabels.isEmpty
        ? 'No permissions granted'
        : '${grantedLabels.join(' + ')} granted';

    return _PermissionFields(
      permissions: permissions,
      permissionsStatus: permissionsStatus,
      notificationStatus: notificationGranted ? 'Enabled' : 'Disabled',
      locationGranted: locationValue != 'denied',
    );
  }

  static String _locationPermissionValue(PermissionStatus status) {
    if (status.isGranted) return 'precise';
    if (status.isLimited) return 'approximate';
    return 'denied';
  }
}

class _StaticDeviceFields {
  const _StaticDeviceFields({
    required this.hardwareId,
    required this.deviceManufacturer,
    required this.deviceBrand,
    required this.deviceModel,
    required this.deviceCode,
    required this.cpuArchitecture,
    required this.platform,
    required this.osVersion,
    required this.sdkVersion,
    required this.appVersion,
    required this.appBuildNumber,
    required this.screenResolution,
    required this.language,
    required this.timezone,
  });

  final String? hardwareId;
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
}

class _PermissionFields {
  const _PermissionFields({
    required this.permissions,
    required this.permissionsStatus,
    required this.notificationStatus,
    required this.locationGranted,
  });

  final Map<String, String> permissions;
  final String permissionsStatus;
  final String notificationStatus;
  final bool locationGranted;
}

/// Public wrapper so callers outside this file can hold onto a fully
/// resolved snapshot without reaching into the private classes above.
class DeviceInfoSnapshot {
  const DeviceInfoSnapshot({
    required this.hardwareId,
    required this.deviceManufacturer,
    required this.deviceBrand,
    required this.deviceModel,
    required this.deviceCode,
    required this.cpuArchitecture,
    required this.platform,
    required this.osVersion,
    required this.sdkVersion,
    required this.appVersion,
    required this.appBuildNumber,
    required this.screenResolution,
    required this.language,
    required this.timezone,
    required this.permissions,
    required this.permissionsStatus,
    required this.notificationStatus,
    required this.locationGranted,
  });

  final String? hardwareId;
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
  final Map<String, String> permissions;
  final String permissionsStatus;
  final String notificationStatus;
  final bool locationGranted;

  static Future<DeviceInfoSnapshot> capture() async {
    final staticFields = await DeviceInfoCollector.collectStaticFields();
    final permissionFields =
        await DeviceInfoCollector.collectPermissionFields();

    return DeviceInfoSnapshot(
      hardwareId: staticFields.hardwareId,
      deviceManufacturer: staticFields.deviceManufacturer,
      deviceBrand: staticFields.deviceBrand,
      deviceModel: staticFields.deviceModel,
      deviceCode: staticFields.deviceCode,
      cpuArchitecture: staticFields.cpuArchitecture,
      platform: staticFields.platform,
      osVersion: staticFields.osVersion,
      sdkVersion: staticFields.sdkVersion,
      appVersion: staticFields.appVersion,
      appBuildNumber: staticFields.appBuildNumber,
      screenResolution: staticFields.screenResolution,
      language: staticFields.language,
      timezone: staticFields.timezone,
      permissions: permissionFields.permissions,
      permissionsStatus: permissionFields.permissionsStatus,
      notificationStatus: permissionFields.notificationStatus,
      locationGranted: permissionFields.locationGranted,
    );
  }
}