import 'dart:async';

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

  /// Emits `true` whenever the device transitions from offline -> online.
  /// (Does not emit on the reverse transition or on duplicate "still
  /// online" results — listeners only care about the "came back" edge.)
  Stream<bool> get onBackOnline => _onlineController.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _lastKnownOnline;
  bool _started = false;

  /// Call once, early in app startup (e.g. from `main()` or
  /// `AppLaunchGate.initState`). Safe to call more than once — subsequent
  /// calls are no-ops.
  void start() {
    if (_started) return;
    _started = true;

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _isOnline(results);

      if (isOnline && _lastKnownOnline == false) {
        _onlineController.add(true);
      }

      _lastKnownOnline = isOnline;
    });
  }

  Future<bool> isOnlineNow() async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = _isOnline(results);
    _lastKnownOnline = isOnline;
    return isOnline;
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
    _started = false;
  }
}