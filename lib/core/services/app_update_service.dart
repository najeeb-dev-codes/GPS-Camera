import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../models/app_update_info.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import 'connectivity_service.dart';

enum AppUpdateCheckState {
  idle,
  checking,
  waitingForInternet,
  completed,
  failed,
  forceUpdateRequired,
}

/// Performs the app-version check once at launch and retries that launch check
/// when a device that started offline gains verified internet access.
///
/// A new check can also be requested when the app returns after a meaningful
/// background interval. Network/server failures never lock the user out.
/// Every update reported by the backend is mandatory: both `force_update`
/// and `is_update_available` enter the same non-dismissible update state.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  final ConnectivityService _connectivity = ConnectivityService.instance;

  StreamSubscription<bool>? _internetSubscription;
  AppUpdateCheckState _state = AppUpdateCheckState.idle;
  AppUpdateInfo? _updateInfo;
  Future<void>? _activeCheck;
  bool _started = false;

  AppUpdateCheckState get state => _state;
  AppUpdateInfo? get updateInfo => _updateInfo;

  bool get requiresForceUpdate =>
      _state == AppUpdateCheckState.forceUpdateRequired;

  bool get shouldBlockFullScreenAds =>
      _state == AppUpdateCheckState.idle ||
      _state == AppUpdateCheckState.checking ||
      _state == AppUpdateCheckState.waitingForInternet ||
      requiresForceUpdate;

  /// Starts the launch check. Safe to call more than once.
  Future<void> start() {
    if (_started) return _activeCheck ?? Future<void>.value();

    _started = true;
    _connectivity.start();
    _internetSubscription =
        _connectivity.onInternetStatusChanged.listen((hasInternet) {
      if (hasInternet && _state == AppUpdateCheckState.waitingForInternet) {
        unawaited(checkForUpdate());
      }
    });

    return checkForUpdate();
  }

  /// Checks again when the app is opened from a real background interval.
  Future<void> checkAfterResume() {
    if (requiresForceUpdate) return Future<void>.value();
    return checkForUpdate();
  }

  Future<void> checkForUpdate() {
    final runningCheck = _activeCheck;
    if (runningCheck != null) return runningCheck;
    if (requiresForceUpdate) return Future<void>.value();

    final check = _performCheck();
    _activeCheck = check;
    return check.whenComplete(() {
      if (identical(_activeCheck, check)) {
        _activeCheck = null;
      }
    });
  }

  Future<void> _performCheck() async {
    _setState(AppUpdateCheckState.checking);

    try {
      final hasInternet = await _connectivity.hasInternetAccess();
      if (!hasInternet) {
        _setState(AppUpdateCheckState.waitingForInternet);
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final platform = _platformName;

      // Add the debug print here
      debugPrint(
        'Version API request: version=${packageInfo.version}, '
        'platform=$platform',
      );

      final response = await DioClient.instance.dio
          .get<dynamic>(
            '${AppConfig.appVersionBaseUrl}${ApiEndpoints.appVersion}',
            queryParameters: <String, dynamic>{
              'version': packageInfo.version,
              'platform': platform,
            },
            options: Options(
              headers: const <String, String>{
                'Accept': 'application/json',
              },
            ),
          )
          .timeout(const Duration(seconds: 50));

      if (!_isSuccessful(response.statusCode)) {
        throw StateError(
          'Version API returned HTTP ${response.statusCode}.',
        );
      }

      final body = _asStringMap(response.data);
      final data = _asStringMap(body?['data']);
      if (body == null || body['status'] != true || data == null) {
        throw const FormatException('Invalid app-version response.');
      }

      final info = AppUpdateInfo.fromJson(
        data,
        platform: platform,
      );
      _updateInfo = info;

      // This app has no optional-update flow. If any newer version is
      // available, require the user to install it before continuing.
      if (info.forceUpdate || info.isUpdateAvailable) {
        _setState(AppUpdateCheckState.forceUpdateRequired);
      } else {
        _setState(AppUpdateCheckState.completed);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('App-version check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _setState(AppUpdateCheckState.failed);
    }
  }

  String get _platformName {
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  bool _isSuccessful(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is! Map) return null;
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  void _setState(AppUpdateCheckState nextState) {
    if (_state == nextState) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    _internetSubscription = null;
    super.dispose();
  }
}
