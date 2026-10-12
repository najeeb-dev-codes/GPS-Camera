import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized Firebase Analytics and Crashlytics integration.
///
/// Keeping monitoring here prevents screens from depending directly on
/// Firebase and ensures reporting failures never interrupt the app flow.
abstract final class FirebaseMonitoringService {
  FirebaseMonitoringService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics =
      FirebaseCrashlytics.instance;
  static final FirebaseAnalyticsObserver _analyticsObserver =
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void>? _initialization;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// Observer used by [MaterialApp] to report route changes to Analytics.
  static List<NavigatorObserver> get navigatorObservers =>
      <NavigatorObserver>[_analyticsObserver];

  /// Enables collection and installs global error handlers once.
  static Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      _installCrashHandlers();

      await _crashlytics.setCustomKey(
        'build_mode',
        kReleaseMode ? 'release' : 'debug',
      );
      await _crashlytics.setCustomKey('app_module', 'gps_mark');
    } catch (error, stackTrace) {
      debugPrint('Crashlytics initialization failed: $error');
      debugPrint('$stackTrace');
    }

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
    } catch (error, stackTrace) {
      debugPrint('Analytics initialization failed: $error');
      debugPrint('$stackTrace');
    }

    _initialized = true;
  }

  static void _installCrashHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _crashlytics.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(
        _crashlytics.recordError(
          error,
          stack,
          fatal: true,
          reason: 'Uncaught asynchronous error',
        ),
      );
      return true;
    };
  }

  /// Logs an app-specific Analytics event without allowing telemetry failures
  /// to affect the user experience.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event "$name" failed: $error');
    }
  }

  /// Records handled failures that should be investigated but must not crash
  /// the application.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_initialized) return;

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: false,
        reason: reason,
      );
    } catch (reportingError) {
      debugPrint('Unable to report non-fatal error: $reportingError');
    }
  }

  /// Adds a lightweight breadcrumb to the next Crashlytics report.
  static void log(String message) {
    if (!_initialized) return;
    _crashlytics.log(message);
  }
}
