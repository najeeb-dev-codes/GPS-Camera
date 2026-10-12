import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// App-wide connectivity signal. This is the single mechanism both photo
/// sync and device registration should listen to for "we just came back
/// online, retry whatever is pending" — keep it here rather than
/// duplicating a listener per feature.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _internetStatusController =
      StreamController<bool>.broadcast();

  /// Emits `true` whenever the device transitions from offline -> online.
  /// (Does not emit on the reverse transition or on duplicate "still
  /// online" results — listeners only care about the "came back" edge.)
  Stream<bool> get onBackOnline => _onlineController.stream;

  /// Emits when verified internet access changes. This is intentionally
  /// different from raw Wi-Fi/mobile connectivity because a connected
  /// network can still have no usable internet.
  Stream<bool> get onInternetStatusChanged => _internetStatusController.stream;

  bool? get lastKnownInternetAccess => _lastKnownInternetAccess;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _lastKnownOnline;
  bool? _lastKnownInternetAccess;
  bool _started = false;
  int _statusCheckGeneration = 0;

  /// Call once, early in app startup (e.g. from `main()` or
  /// `AppLaunchGate.initState`). Safe to call more than once — subsequent
  /// calls are no-ops.
  void start() {
    if (_started) return;
    _started = true;

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      unawaited(_refreshInternetStatus(results: results));
    });

    unawaited(_refreshInternetStatus());
  }

  Future<bool> isOnlineNow() async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = _isOnline(results);
    _lastKnownOnline = isOnline;
    return isOnline;
  }

  /// Confirms that the device has both a network connection and usable
  /// internet access. A Wi-Fi connection alone can still have no internet.
  Future<bool> hasInternetAccess({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final generation = ++_statusCheckGeneration;
    final results = await _connectivity.checkConnectivity();
    final online = _isOnline(results);
    _lastKnownOnline = online;
    if (!online) {
      if (generation == _statusCheckGeneration) {
        _publishInternetStatus(false);
      }
      return false;
    }

    final hasAccess = await _canReachInternet(timeout);
    if (generation == _statusCheckGeneration) {
      _publishInternetStatus(hasAccess);
    }
    return hasAccess;
  }

  Future<void> _refreshInternetStatus({
    List<ConnectivityResult>? results,
  }) async {
    final generation = ++_statusCheckGeneration;
    final currentResults = results ?? await _connectivity.checkConnectivity();
    final online = _isOnline(currentResults);
    _lastKnownOnline = online;

    if (!online) {
      _publishInternetStatus(false);
      return;
    }

    final hasAccess = await _canReachInternet(const Duration(seconds: 4));
    if (generation != _statusCheckGeneration) return;
    _publishInternetStatus(hasAccess);
  }

  Future<bool> _canReachInternet(Duration timeout) async {

    Socket? socket;
    try {
      socket = await Socket.connect(
        'example.com',
        443,
        timeout: timeout,
      );
      return true;
    } on Object {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  void _publishInternetStatus(bool hasAccess) {
    final previous = _lastKnownInternetAccess;
    if (previous == hasAccess) return;

    _lastKnownInternetAccess = hasAccess;
    _internetStatusController.add(hasAccess);
    if (hasAccess && previous == false) {
      _onlineController.add(true);
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
    _internetStatusController.close();
    _started = false;
  }
}
