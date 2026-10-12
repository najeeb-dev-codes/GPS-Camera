import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_brand.dart';
import 'app_settings_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android channel behaviour cannot be changed after a channel is created.
  // Separate channels keep every saved sound/vibration combination functional.
  static const AndroidNotificationChannel _soundAndVibrationChannel =
      AndroidNotificationChannel(
    'gps_camera_sound_vibration_v2',
    '${AppBrand.name} - Sound and Vibration',
    description: '${AppBrand.name} notifications with sound and vibration',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _soundChannel =
      AndroidNotificationChannel(
    'gps_camera_sound_v2',
    '${AppBrand.name} - Sound',
    description: '${AppBrand.name} notifications with sound',
    importance: Importance.max,
    playSound: true,
    enableVibration: false,
  );

  static const AndroidNotificationChannel _vibrationChannel =
      AndroidNotificationChannel(
    'gps_camera_vibration_v2',
    '${AppBrand.name} - Vibration',
    description: '${AppBrand.name} notifications with vibration',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _silentChannel =
      AndroidNotificationChannel(
    'gps_camera_silent_v2',
    '${AppBrand.name} - Silent',
    description: 'Silent ${AppBrand.name} notifications',
    importance: Importance.high,
    playSound: false,
    enableVibration: false,
  );

  static const List<AndroidNotificationChannel> _channels = [
    _soundAndVibrationChannel,
    _soundChannel,
    _vibrationChannel,
    _silentChannel,
  ];

  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    final activeInitialization = _initializing;
    if (activeInitialization != null) return activeInitialization;
    final initialization = _initialize();
    _initializing = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    try {
      await AppSettingsService.instance.ensureNotificationSettingsLoaded();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
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
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      for (final channel in _channels) {
        await androidPlugin?.createNotificationChannel(channel);
      }

      // Foreground FCM messages are displayed manually below. This prevents a
      // duplicate iOS notification and lets the saved sound setting take effect.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      _initialized = true;
      // Runtime notification access is requested only from the onboarding
      // permission screen or when the user explicitly enables its toggle.
      // Initialization must never display an OS dialog before Welcome.
      debugPrint('NotificationService initialized');
    } finally {
      _initializing = null;
    }
  }

  Future<void> requestPermissions() async {
    await initialize();
    await _requestPlatformPermissions();
  }

  Future<void> _requestPlatformPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        AppBrand.name;
    final body =
        notification?.body ?? message.data['body']?.toString() ?? '';

    await showAppNotification(
      id: _notificationId(message),
      title: title,
      body: body,
      payload: message.data,
    );
  }

  /// Displays an app-generated notification using the current persisted
  /// master, sound and vibration settings.
  Future<void> showAppNotification({
    required String title,
    required String body,
    Map<String, dynamic> payload = const <String, dynamic>{},
    int? id,
  }) async {
    final settings = AppSettingsService.instance;
    await settings.ensureNotificationSettingsLoaded();
    if (!settings.masterNotifications ||
        (title.isEmpty && body.isEmpty)) {
      return;
    }

    await initialize();

    final channel = _channelFor(
      sound: settings.notificationSound,
      vibration: settings.notificationVibration,
    );
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: settings.notificationSound,
      enableVibration: settings.notificationVibration,
      icon: '@mipmap/ic_launcher',
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: settings.notificationSound,
    );

    await _localNotifications.show(
      id: id ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(payload),
    );
  }

  static AndroidNotificationChannel _channelFor({
    required bool sound,
    required bool vibration,
  }) {
    if (sound && vibration) return _soundAndVibrationChannel;
    if (sound) return _soundChannel;
    if (vibration) return _vibrationChannel;
    return _silentChannel;
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      debugPrint('Notification data: $data');
    } catch (error) {
      debugPrint('Notification payload parse failed: $error');
    }
  }

  Future<void> handleRemoteMessageTap(RemoteMessage message) async {
    debugPrint('FCM notification tapped: ${message.messageId}');
    debugPrint('Notification data: ${message.data}');
  }

  static int _notificationId(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null) return messageId.hashCode & 0x7fffffff;
    return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
  }
}

