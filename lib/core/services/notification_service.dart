import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel
      _highImportanceChannel =
      AndroidNotificationChannel(
    'gps_camera_high_importance',
    'GPS Camera Notifications',
    description:
        'Important notifications from GPS Camera',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<void> initialize() async {
    if (_initialized) return;

    // -------------------------------------------------------------------------
    // ANDROID INITIALIZATION
    // -------------------------------------------------------------------------

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // -------------------------------------------------------------------------
    // IOS INITIALIZATION
    // -------------------------------------------------------------------------

    const iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTapped,
    );

    // -------------------------------------------------------------------------
    // CREATE ANDROID CHANNEL
    // -------------------------------------------------------------------------

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _highImportanceChannel,
    );

    // -------------------------------------------------------------------------
    // IOS FOREGROUND PRESENTATION
    // -------------------------------------------------------------------------

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;

    debugPrint(
      '✅ NotificationService initialized',
    );
  }

  // ===========================================================================
  // FOREGROUND MESSAGE
  // ===========================================================================

  Future<void> showForegroundNotification(
    RemoteMessage message,
  ) async {
    debugPrint(
      '📩 Foreground FCM received',
    );

    debugPrint(
      'Message ID: ${message.messageId}',
    );

    debugPrint(
      'Data: ${message.data}',
    );

    final notification =
        message.notification;

    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'GPS Camera';

    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        '';

    // If there is no visible content,
    // don't create an empty notification.
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final androidDetails =
        AndroidNotificationDetails(
      _highImportanceChannel.id,
      _highImportanceChannel.name,
      channelDescription:
          _highImportanceChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: _notificationId(message),
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(
        message.data,
      ),
    );

    debugPrint(
      '✅ Foreground notification displayed',
    );
  }

  // ===========================================================================
  // NOTIFICATION TAP
  // ===========================================================================

  static void _onLocalNotificationTapped(
    NotificationResponse response,
  ) {
    debugPrint(
      '🔔 Local notification tapped',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );

    if (response.payload == null ||
        response.payload!.isEmpty) {
      return;
    }

    try {
      final data =
          jsonDecode(response.payload!);

      debugPrint(
        'Notification data: $data',
      );

      // Later:
      // Navigate based on:
      //
      // data['type']
      // data['screen']
      // data['project_id']
      //
      // Example:
      //
      // if (data['screen'] == 'gallery') {
      //   AppNavigator.openGallery();
      // }
    } catch (e) {
      debugPrint(
        'Notification payload parse failed: $e',
      );
    }
  }

  // ===========================================================================
  // REMOTE NOTIFICATION TAP
  // ===========================================================================

  Future<void> handleRemoteMessageTap(
    RemoteMessage message,
  ) async {
    debugPrint(
      '🔔 FCM notification tapped',
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

    // -------------------------------------------------------------------------
    // NAVIGATION
    // -------------------------------------------------------------------------

    // Later you can use data values here.
    //
    // final screen = message.data['screen'];
    //
    // if (screen == 'gallery') {
    //   AppNavigator.openGallery();
    // }
    //
    // if (screen == 'projects') {
    //   AppNavigator.openProjects();
    // }
  }

  // ===========================================================================
  // UNIQUE NOTIFICATION ID
  // ===========================================================================

  static int _notificationId(
    RemoteMessage message,
  ) {
    final messageId =
        message.messageId;

    if (messageId != null) {
      return messageId
              .hashCode &
          0x7fffffff;
    }

    return DateTime.now()
            .millisecondsSinceEpoch
            .remainder(
              2147483647,
            );
  }
}