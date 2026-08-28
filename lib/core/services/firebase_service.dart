


import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart'
    as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;
  static bool _listenersAttached = false;

  static bool get isInitialized =>
      _initialized;

  // ===========================================================================
  // INITIALIZE FIREBASE
  // ===========================================================================

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await firebase_core.Firebase
          .initializeApp();

      _initialized = true;

      debugPrint(
        '✅ FirebaseService: '
        'Firebase initialized successfully',
      );

      // Initialize local notification system.
      await NotificationService.instance
          .initialize();

      // Attach foreground / interaction listeners.
      _attachMessageListeners();
    } catch (e, stackTrace) {
      debugPrint(
        '❌ FirebaseService.initialize failed: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ===========================================================================
  // FCM LISTENERS
  // ===========================================================================

  static void _attachMessageListeners() {
    if (_listenersAttached) {
      return;
    }

    _listenersAttached = true;

    // -------------------------------------------------------------------------
    // FOREGROUND
    // -------------------------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint(
          '📩 FOREGROUND MESSAGE RECEIVED',
        );

        debugPrint(
          'Message ID: ${message.messageId}',
        );

        debugPrint(
          'Title: ${message.notification?.title}',
        );

        debugPrint(
          'Body: ${message.notification?.body}',
        );

        debugPrint(
          'Data: ${message.data}',
        );

        await NotificationService.instance
            .showForegroundNotification(
          message,
        );
      },
    );

    // -------------------------------------------------------------------------
    // BACKGROUND -> USER TAPS NOTIFICATION
    // -------------------------------------------------------------------------

    FirebaseMessaging
        .onMessageOpenedApp
        .listen(
      (RemoteMessage message) async {
        debugPrint(
          '🔔 BACKGROUND NOTIFICATION OPENED',
        );

        await NotificationService.instance
            .handleRemoteMessageTap(
          message,
        );
      },
    );
  }

  // ===========================================================================
  // TERMINATED -> USER TAPS NOTIFICATION
  // ===========================================================================

  static Future<void>
      handleInitialMessage() async {
    if (!_initialized) {
      return;
    }

    try {
      final message =
          await FirebaseMessaging.instance
              .getInitialMessage();

      if (message == null) {
        return;
      }

      debugPrint(
        '🚀 APP OPENED FROM TERMINATED NOTIFICATION',
      );

      debugPrint(
        'Message ID: ${message.messageId}',
      );

      await NotificationService.instance
          .handleRemoteMessageTap(
        message,
      );
    } catch (e) {
      debugPrint(
        '❌ getInitialMessage failed: $e',
      );
    }
  }

  // ===========================================================================
  // FIREBASE INSTALLATION ID
  // ===========================================================================

  static Future<String?>
      getFirebaseInstallationId() async {
    if (!_initialized) {
      return null;
    }

    try {
      final id =
          await FirebaseInstallations
              .instance
              .getId();

      debugPrint(
        'Firebase installation ID: $id',
      );

      return id;
    } catch (e) {
      debugPrint(
        'FirebaseService.'
        'getFirebaseInstallationId failed: $e',
      );

      return null;
    }
  }

  // ===========================================================================
  // GET FCM TOKEN
  // ===========================================================================

  static Future<String?>
      getFcmToken() async {
    if (!_initialized) {
      return null;
    }

    try {
      final token =
          await FirebaseMessaging.instance
              .getToken();

      debugPrint(
        'FCM token: $token',
      );

      return token;
    } catch (e) {
      debugPrint(
        'FirebaseService.'
        'getFcmToken failed: $e',
      );

      return null;
    }
  }

  // ===========================================================================
  // TOKEN REFRESH
  // ===========================================================================

  static void listenForTokenRefresh({
    required Future<void> Function(
      String token,
    ) onTokenRefresh,
  }) {
    FirebaseMessaging.instance
        .onTokenRefresh
        .listen(
      (String token) async {
        debugPrint(
          '🔄 FCM token refreshed',
        );

        debugPrint(
          'New token: $token',
        );

        await onTokenRefresh(
          token,
        );
      },
    );
  }
}