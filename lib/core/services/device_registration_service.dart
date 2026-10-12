import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import 'connectivity_service.dart';
import 'device_info_collector.dart';
import 'firebase_service.dart';
import 'installation_id_service.dart';
import 'location_service.dart';
import '../models/device_registaraction_payload.dart';

/// Device registration is the one "online-only" call in an otherwise
/// offline-first app. This service:
///
///  1. Builds the payload FRESH every time it sends (never reuses a stale
///     snapshot) so it always reflects the latest permission/location
///     state — see [DeviceInfoSnapshot.capture].
///  2. Fires once on first launch, and again any time permission state
///     changes materially (call [registerAfterPermissionsChanged] after
///     the permission flow completes).
///  3. If offline, doesn't fail silently and doesn't crash the offline
///     -first flow — it just flips a `pending` flag in SharedPreferences
///     and relies on [ConnectivityService.onBackOnline] to retry, exactly
///     like photo sync does for its own queue.
///
/// Note on the queue: we deliberately store only a boolean "there is a
/// registration pending" flag, not a serialized payload — the payload is
/// rebuilt fresh at send time anyway (permissions/location may have
/// changed between when it was queued and when connectivity comes back),
/// so a stored payload would just be stale data we'd throw away.
///
/// Networking goes through the shared `DioClient.instance` (see
/// `core/network/dio_client.dart`) rather than creating its own client —
/// that's where base URL / timeouts / logging / connection-error retry
/// are configured, once, for the whole app.
class DeviceRegistrationService {
  DeviceRegistrationService._();

  static const String _pendingKey = 'device_registration_pending_v1';
  static const String _lastRegisteredAtKey =
      'device_registration_last_success_v1';
  static const String _locationSentOnceKey =
      'device_registration_location_sent_once_v1';
  static const String _pendingFirstLocationKey =
      'device_registration_first_location_pending_v1';

  static final Dio _dio = DioClient.instance.dio;
  static bool _retryListenerAttached = false;
  static bool _inFlight = false;
  static bool _rerunRequested = false;
  static bool _rerunWantsFirstInstallLocation = false;

  // ---------------------------------------------------------------------
  // PUBLIC ENTRY POINTS
  // ---------------------------------------------------------------------

  /// Call once, early in app startup (e.g. from `AppLaunchGate.initState`,
  /// right after `ConnectivityService.instance.start()`). Attempts an
  /// immediate registration; if offline, queues it silently — the app
  /// keeps working offline-first regardless of the outcome here.
  static Future<void> registerOnLaunch() async {
    _attachRetryListenerOnce();

    // Normal launches must NOT keep sending location. The only exception
    // is when the one-time first-install location upload was queued earlier
    // (for example because the device was offline when permission was granted).
    final retryFirstLocation = await _hasPendingFirstLocation();
    await registerNow(includeFirstInstallLocation: retryFirstLocation);
  }

  /// Call after the permission flow completes (granted or not — a denial
  /// is itself useful info for `permissions_status`) so the backend gets
  /// an updated payload with real permission/location fields instead of
  /// the minimal first-launch snapshot.
  static Future<void> registerAfterPermissionsChanged() async {
    // This method may be called more than once by the permission flow, but
    // location is included only until the first successful location upload
    // for this installation. SharedPreferences is cleared by uninstall, so a
    // fresh install naturally gets one new location upload.
    await registerNow(includeFirstInstallLocation: true);
  }

  /// Attempts registration right now. Safe to call repeatedly — a second
  /// call while one is already in flight is a no-op. Never throws: all
  /// failures are caught and turned into a queued retry.
  static Future<void> registerNow({
    bool includeFirstInstallLocation = false,
  }) async {
    if (_inFlight) {
      _rerunRequested = true;
      _rerunWantsFirstInstallLocation =
          _rerunWantsFirstInstallLocation || includeFirstInstallLocation;
      return;
    }

    _inFlight = true;

    try {
      final locationAlreadySent = await _hasSentLocationOnce();
      final shouldTryFirstLocation =
          includeFirstInstallLocation && !locationAlreadySent;

      final isOnline = await ConnectivityService.instance.isOnlineNow();

      if (!isOnline) {
        await _markPending(
          needsFirstLocation: shouldTryFirstLocation,
        );
        return;
      }

      final payload = await _buildPayload(
        includeLocation: shouldTryFirstLocation,
      );

      // Only treat the one-time location as captured when a real GPS
      // coordinate exists. If GPS/location service is temporarily
      // unavailable, keep this first-install upload pending for a later retry.
      final hasRealLocation =
          payload.latitude != null && payload.longitude != null;
      final sendLocationKeys = shouldTryFirstLocation && hasRealLocation;

      final success = await _send(
        payload,
        includeLocation: sendLocationKeys,
      );

      if (success) {
        if (sendLocationKeys) {
          await _markLocationSentOnce();
          await _clearPendingFirstLocation();
        } else if (shouldTryFirstLocation) {
          await _markPendingFirstLocation();
        }

        await _clearPending();
      } else {
        await _markPending(
          needsFirstLocation: shouldTryFirstLocation,
        );
      }
    } catch (_) {
      await _markPending(
        needsFirstLocation: includeFirstInstallLocation,
      );
    } finally {
      _inFlight = false;

      if (_rerunRequested) {
        final wantsFirstLocation = _rerunWantsFirstInstallLocation;
        _rerunRequested = false;
        _rerunWantsFirstInstallLocation = false;
        unawaited(
          registerNow(
            includeFirstInstallLocation: wantsFirstLocation,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // PAYLOAD
  // ---------------------------------------------------------------------

  static Future<DeviceRegistrationPayload> _buildPayload({
    required bool includeLocation,
  }) async {
    final installationId = await InstallationIdService.getOrCreate();
    final snapshot = await DeviceInfoSnapshot.capture();

    // Firebase and location reads run independently and in parallel —
    // neither depends on the other, and both are best-effort (each
    // already swallows its own errors and returns nulls on failure), so
    // there's no reason to make one wait on the other.
    final results = await Future.wait([
      FirebaseService.getFirebaseInstallationId(),
      FirebaseService.getFcmToken(),
      includeLocation && snapshot.locationGranted
          ? LocationService.captureFresh()
          : Future.value(const LocationSnapshot()),
    ]);

    final firebaseInstallationId = results[0] as String?;
    final fcmToken = results[1] as String?;
    final location = results[2] as LocationSnapshot;

    return DeviceRegistrationPayload(
      installationId: installationId,
      packageName: snapshot.packageName,
      firebaseInstallationId: firebaseInstallationId,
      fcmToken: fcmToken,
      hardwareId: snapshot.hardwareId,
      deviceManufacturer: snapshot.deviceManufacturer,
      deviceBrand: snapshot.deviceBrand,
      deviceModel: snapshot.deviceModel,
      deviceCode: snapshot.deviceCode,
      cpuArchitecture: snapshot.cpuArchitecture,
      platform: snapshot.platform,
      osVersion: snapshot.osVersion,
      sdkVersion: snapshot.sdkVersion,
      appVersion: snapshot.appVersion,
      appBuildNumber: snapshot.appBuildNumber,
      screenResolution: snapshot.screenResolution,
      language: snapshot.language,
      timezone: snapshot.timezone,
      permissions: snapshot.permissions,
      permissionsStatus: snapshot.permissionsStatus,
      notificationStatus: snapshot.notificationStatus,
      latitude: location.latitude,
      longitude: location.longitude,
      city: location.city,
      state: location.state,
      country: location.country,
      countryCode: location.countryCode,
    );
  }

  // ---------------------------------------------------------------------
  // NETWORK
  // ---------------------------------------------------------------------

  static Future<bool> _send(
    DeviceRegistrationPayload payload, {
    required bool includeLocation,
  }) async {
    try {
      final data = payload.toJson();

      // After the first successful location upload, do not send these keys
      // again at all. Sending them as null on later launches could overwrite
      // the location already stored by the backend.
      if (!includeLocation) {
        data.remove('latitude');
        data.remove('longitude');
        data.remove('city');
        data.remove('state');
        data.remove('country');
        data.remove('country_code');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.deviceRegister,
        data: data,
      );

      final status = response.statusCode ?? 0;

      if (status == 200 || status == 201) {
        await _rememberSuccess();

        // ignore: avoid_print
        print('✅ Device data successfully sent to backend');

        // ignore: avoid_print
        print('✅ Status code: $status');

        // ignore: avoid_print
        print('✅ Backend response: ${response.data}');

        return true;
      }

      // 4xx (e.g. 422 validation error) — a retry with the exact same
      // payload shape won't help, but we don't want to spin forever
      // either. Treat as "handled" so we don't wedge the pending flag,
      // while still surfacing it for debugging.
      if (status >= 400 && status < 500) {
        // ignore: avoid_print
        print('Device registration rejected ($status): ${response.data}');
        return true;
      }

      // 5xx — worth retrying later.
      return false;
    } on DioException catch (e) {
      // Covers timeouts, connection errors, DNS failures, etc. — all
      // worth a later retry via the offline queue.
      // ignore: avoid_print
      print('Device registration request failed: ${e.message}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Device registration unexpected error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // PENDING / RETRY-ON-RECONNECT
  // ---------------------------------------------------------------------

  static void _attachRetryListenerOnce() {
    if (_retryListenerAttached) return;
    _retryListenerAttached = true;

    ConnectivityService.instance.onBackOnline.listen((_) async {
      if (await _hasPending()) {
        await registerNow(
          includeFirstInstallLocation: await _hasPendingFirstLocation(),
        );
      }
    });
  }

  static Future<bool> _hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingKey) ?? false;
  }

  static Future<void> _markPending({
    bool needsFirstLocation = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, true);
    if (needsFirstLocation) {
      await prefs.setBool(_pendingFirstLocationKey, true);
    }
  }

  static Future<void> _clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingKey, false);
  }


  static Future<bool> _hasSentLocationOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationSentOnceKey) ?? false;
  }

  static Future<void> _markLocationSentOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationSentOnceKey, true);
  }

  static Future<bool> _hasPendingFirstLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingFirstLocationKey) ?? false;
  }

  static Future<void> _markPendingFirstLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingFirstLocationKey, true);
  }

  static Future<void> _clearPendingFirstLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingFirstLocationKey, false);
  }

  static Future<void> _rememberSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastRegisteredAtKey,
      DateTime.now().toIso8601String(),
    );
  }
}
