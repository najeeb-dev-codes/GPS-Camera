


import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart'
    as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';

// =============================================================================
// FCM BACKGROUND HANDLER
// =============================================================================
//
// This MUST:
//
// 1. Be top-level.
// 2. Have @pragma('vm:entry-point').
// 3. Initialize Firebase before using Firebase services.
//
// Android may execute this inside a separate isolate.
//
// IMPORTANT:
// If the backend sends a normal "notification" payload while the app is
// backgrounded or terminated, Android/iOS displays it automatically.
//
// Therefore we DO NOT manually call localNotifications.show() here for normal
// notification+data messages, otherwise Android may display TWO notifications.
//
// This handler is mainly for:
// - logging
// - data processing
// - saving values
// - syncing
// - data-only FCM handling
//
@pragma('vm:entry-point')
Future<void>
    firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await firebase_core.Firebase
      .initializeApp();

  debugPrint(
    '📩 BACKGROUND/TERMINATED FCM RECEIVED',
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
}

// =============================================================================
// MAIN
// =============================================================================

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

  // Keep every app screen in portrait. The camera module reads the physical
  // device orientation separately, so only its stamp/brightness overlays can
  // rotate while the application layout remains upright.
  await SystemChrome.setPreferredOrientations(
    const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ],
  );

  // ---------------------------------------------------------------------------
  // REGISTER BACKGROUND HANDLER
  // ---------------------------------------------------------------------------

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // ---------------------------------------------------------------------------
  // INITIALIZE FIREBASE
  // ---------------------------------------------------------------------------

  await FirebaseService.initialize();

  // ---------------------------------------------------------------------------
  // START APP
  // ---------------------------------------------------------------------------

  runApp(
    const ProviderScope(
      child: GPSCameraApp(),
    ),
  );

  // ---------------------------------------------------------------------------
  // TERMINATED NOTIFICATION TAP
  // ---------------------------------------------------------------------------
  //
  // run after application initialization so your app/navigation tree exists.

  WidgetsBinding.instance
      .addPostFrameCallback(
    (_) async {
      await FirebaseService
          .handleInitialMessage();
    },
  );
}
